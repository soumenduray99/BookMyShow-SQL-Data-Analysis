create database BookMyShow;
use BookMyShow;
SET SQL_SAFE_UPDATES = 0;
SET FOREIGN_KEY_CHECKS = 0;

create table C_User(
  user_id varchar(300) primary key,	
  c_name char(250),
  email varchar(300),
  phone_number bigint,
  DOB date
);

create table Movies (
 movie_id varchar(300) primary key,
 title	char(250),
 genre	varchar(200),
 m_lang  char(250),  	
 duration int,
 rating	float,
 release_date date,	
 descp char(250)	
);

create table Theaters(
 theater_id	varchar(300) primary key,
 t_name char(250),
 location varchar(200),
 city char(250),
 state char(200)
);

create table Screens(
  screen_id varchar(300) primary key,
  theater_id varchar(300),
  screen_number int,
  total_seats int
);

create table Shows(
 show_id varchar(300) primary key,
 movie_id varchar(300),	
 theater_id varchar(300),
 screen_id varchar(300),
 show_date date,
 start_time	time,
 price_per_ticket float,
 available_seats int
);

create table Bookings(
 booking_id varchar(300) primary key,
 user_id varchar(300),
 show_id varchar(300),
 booking_date datetime,
 total_tickets int,
 payment_status char(200)
);

create table Seats(
  seat_id  varchar(300) primary key,
  booking_id varchar(300),
  screen_id varchar(300),
  seat_number varchar(200),
  seat_type char(200),
  charger int,
  status char(200)
);

create table Payments(
 payment_id varchar(300) primary key,
 booking_id varchar(300),
 user_id varchar(300),
 payment_method char(200),
 payment_date datetime,
 transaction_status char(200)
);

create table Reviews (
 review_id 	varchar(300) primary key,
 user_id varchar(300),
 movie_id varchar(300),
 rating float,
 review_text char(200),
 review_date datetime
);

show tables;

describe bookings;
describe c_user;
describe movies;
describe payments;
describe screens;
describe seats;
describe shows;
describe theaters;
describe Reviews;

alter table  screens add foreign key (theater_id) references theaters(theater_id);
alter table bookings add foreign key (user_id) references c_user(user_id),
add foreign key (show_id) references shows(show_id);
alter table payments add foreign key (booking_id) references bookings(booking_id),
add foreign key (user_id) references c_user(user_id);
alter table seats add foreign key  (booking_id) references bookings(booking_id),
add foreign key (screen_id) references screens(screen_id);
alter table shows add foreign key (movie_id) references movies(movie_id),
add foreign key (theater_id) references theaters(theater_id), add foreign key
(screen_id) references screens(screen_id);
alter table Reviews add foreign key (user_id) references c_user(user_id),
add foreign key (movie_id) references movies(movie_id);

select * from bookings;
select * from c_user;
select * from movies;
select * from payments;
select * from screens;
select * from seats;
select * from shows;
select * from theaters;
select * from Reviews;

#-------------------------------------------------------------------------------------------------------------------------------------------#

/* Analysis on BookMyShow */

/* A. User Behavior & Engagement Analysis */
#1.	Retrieve the top 10 most active users based on the no. of times of bookings.
select cu.c_name,count(bk.booking_id) as Booking from bookings as bk join c_user as cu 
on cu.user_id=bk.user_id group by cu.c_name order by Booking desc limit 10; 

#2.	Find how many unique users booked tickets in the past month along with total tickets.
select  cu.c_name , sum(total_tickets)  as total_bookings from bookings as bk join c_user as cu 
on cu.user_id=bk.user_id where booking_date>= date_sub(curdate(),interval 1 month )
group by cu.c_name order by total_bookings desc ;

#3.	Identify users who have booked more than 5 times in the last 6 months.
select  cu.c_name, count(bk.booking_id) as booking_count, sum(total_tickets)  as total_bookings from bookings as bk join c_user as cu 
on cu.user_id=bk.user_id where booking_date >= date_sub(now(),interval 6 month) 
group by cu.c_name having count(bk.booking_id)>5  order by booking_count desc,total_bookings desc ;

#4.	Determine top 5 peak booking month of the year.
select * from 
(select * , rank() over (partition by Years order by  booking_count desc) as Ranks from
(select year(booking_date) as Years , monthname(booking_date) as Months, count(booking_id) as booking_count
from bookings group by Years,Months order by Years desc,booking_count desc) as rnk ) as rk where rk.Ranks<=5 ;

#5.	Identify the top 10 cities with the highest user engagement.
select th.city,th.state, count(bk.booking_id) as booking_count from theaters as th join shows as sh on
sh.theater_id=th.theater_id join bookings as bk on bk.show_id=sh.show_id group by th.city,th.state 
order by booking_count desc limit 10;

#6.	Find the average number of tickets booked per user state wise along with top 5 .
select th.state,round(sum(total_tickets)/count(booking_id),2) as average_ticket_per_user
from  theaters as th join shows as sh on sh.theater_id=th.theater_id join bookings as bk 
on bk.show_id=sh.show_id group by th.state order by average_ticket_per_user desc;

#7.	Identify users who haven't made any bookings in the last 6 months.
select c_name from  bookings as bk join c_user as cu 
on cu.user_id=bk.user_id where booking_date>= date_sub(curdate(),interval 6 month );

#8.	Determine the percentage of repeat customers.
select cu.c_name,count(bk.booking_id)/(select count(*) from bookings)*100 as Booking 
from bookings as bk join c_user as cu on cu.user_id=bk.user_id 
group by cu.c_name having count(bk.booking_id)>1 order by Booking desc limit 10; 

#9.	Find the top 5 users with the highest total spending on bookings.
select cu.c_name,round(sum(total_tickets*price_per_ticket),2) as Total_Spending 
from bookings as bk join c_user as cu on cu.user_id=bk.user_id join shows as sh on 
sh.show_id=bk.show_id group by cu.c_name  order by Total_Spending  desc limit 10; 

#10.Retrieve the statewise top 3 higher booking theater .
select * from 
( select * , rank() over (partition by state order by total_ticket desc) as Ranks from 
( select th.state,th.t_name,sum(bk.total_tickets) as total_ticket from theaters as th join 
shows as sh on sh.theater_id=th.theater_id join bookings as bk on bk.show_id=sh.show_id
group by th.state,th.t_name order by total_ticket desc ) as rnk) as rk where rk.Ranks<=5;

#11.Find the hour of the day with the highest number of bookings.
select hour(booking_date) as Hours,count(bk.booking_id) as Booking from bookings as bk join c_user as cu 
on cu.user_id=bk.user_id group by Hours order by Booking desc limit 10; 

#12.Find the  users who book tickets within 24 hours of the showtime.
select c_name from  bookings as bk join c_user as cu 
on cu.user_id=bk.user_id join shows as sh on sh.show_id=bk.show_id where date(bk.booking_date)=sh.show_date ;

#13.Find the average number of tickets booked per user per month and find its top 20.
select monthname(booking_date) as Months, sum(total_tickets)/count(booking_id) as avg_ticket_per_user from 
bookings as bk join c_user as cu on cu.user_id=bk.user_id 
group by Months order by avg_ticket_per_user desc limit 20;

/* B. Movie Performance Analysis */
#1.	Identify the top 10 highest-rated movies based on user reviews.
select m.title as movie_name, m.genre, round(avg(r.rating),1) as rating from movies as m join
reviews as r on m.movie_id=r.movie_id group by movie_name,m.genre order by rating desc limit 10 ;

#2.	Find the top 20 movies with the most bookings in the last 6 months.
select m.title as movie_name, m.genre,count(bk.booking_id) as total_booking, sum(bk.total_tickets) as total_ticket
from bookings as bk join shows as sh on sh.show_id=bk.show_id join movies as m on m.movie_id=sh.movie_id
where bk.booking_date>=date_sub(bk.booking_date,interval 6 month) group by movie_name,m.genre
order by total_booking desc limit 20;

#3.	Retrieve the top 10 most popular movie genre with total booking with its total tickets.
select m.genre,count(bk.booking_id) as total_booking, sum(bk.total_tickets) as total_ticket
from bookings as bk join shows as sh on sh.show_id=bk.show_id join movies as m on m.movie_id=sh.movie_id
group by m.genre order by total_booking desc limit 10;

#4.	Identify the top 20 least popular movies based on bookings with total tickets .
select m.title as movie_name,count(bk.booking_id) as total_booking, sum(bk.total_tickets) as total_ticket
from bookings as bk join shows as sh on sh.show_id=bk.show_id join movies as m on m.movie_id=sh.movie_id
group by movie_name order by total_booking asc limit 20;

#5.	Find the average occupancy rate per movie.
select m.title as movie_name,sum(bk.total_tickets)/sum(available_seats)*100 as average_occupancy_rate from 
movies as m join shows as sh on sh.movie_id=m.movie_id join bookings as bk on bk.show_id=sh.show_id
group by  movie_name order by average_occupancy_rate desc ;

#6.	Retrieve the top 10 movies with the highest revenue generation.
select m.title as movie_name,round( sum(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) as Total_Revenue 
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join movies as m on m.movie_id=sh.movie_id group by movie_name order by Total_Revenue  desc limit 10;

#7.	Identify the top 5 most popular language for movies.
select m.m_lang as Languages,count(booking_id) as total_booking from bookings as bk join shows as sh
on sh.show_id=bk.show_id join movies as m on m.movie_id=sh.movie_id group by Languages order by total_booking desc limit 5;

#8.	Determine the top 5 for  total revenue generated by a specific genre.
select m.genre as movie_genre,round( sum(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) as Total_Revenue 
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join movies as m on m.movie_id=sh.movie_id group by movie_genre order by Total_Revenue  desc limit 5;

#9.	Find the number of bookings per movie in the last 30 days (top 20).
select m.title as Movies,count(booking_id) as total_booking from bookings as bk join shows as sh
on sh.show_id=bk.show_id join movies as m on m.movie_id=sh.movie_id where booking_date>=date_sub(current_date(), interval 30 day)
group by Movies order by total_booking desc limit 20;

#10. Identify movies that have received a rating below 5.0.
select m.title , round(avg(rv.rating),1) as Rating from movies as m join reviews as rv 
on m.movie_id=rv.movie_id group by  m.title  having Rating<5 order by Rating desc;

#11. Calculate the average occupancy rate per genre.
select m.genre as movie_genre,sum(bk.total_tickets)/sum(available_seats)*100 as average_occupancy_rate from 
movies as m join shows as sh on sh.movie_id=m.movie_id join bookings as bk on bk.show_id=sh.show_id
group by  movie_genre order by average_occupancy_rate desc ;

#12. Identify movies with the lowest occupancy rate.
select m.title as movie_name,sum(bk.total_tickets)/sum(available_seats)*100 as average_occupancy_rate from 
movies as m join shows as sh on sh.movie_id=m.movie_id join bookings as bk on bk.show_id=sh.show_id
group by  movie_name order by average_occupancy_rate asc limit 1 ;

#13. Identify movies that have been screened in more than 20 theaters.
select m.title as movie_name, count(th.theater_id) as theater_count from movies as m join shows as sh 
on sh.movie_id=m.movie_id join theaters as th on th.theater_id=sh.theater_id group by movie_name
having count(th.theater_id)>20 order by  theater_count desc;

#14. Find the movies that are highly rated (rating > 6).
select m.title , round(avg(rv.rating),1) as Rating from movies as m join reviews as rv 
on m.movie_id=rv.movie_id group by  m.title  having Rating>6 order by Rating desc;

#15. Identify movies that have been released but have no bookings within a week.
select m.title from movies as m join shows as sh on sh.movie_id=m.movie_id join bookings as bk on 
bk.show_id=sh.show_id where not bk.booking_date between sh.show_date and date_sub(sh.show_date,interval 7 day);

#16. Calculate the average revenue per movie in the last year.
select m.title as movie_name,round( avg(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) as Avg_Revenue 
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join movies as m on m.movie_id=sh.movie_id where year(bk.booking_date)=2024
group by movie_name order by Avg_Revenue  desc limit 5;

#17. Find the top 5 movies with the highest number of theatres available , along with no. of ticket sold.
select m.title as movie_name, count(th.theater_id) as Total_Theaters, sum(total_tickets) as Total_Tickets
from movies as m join shows as sh on sh.movie_id=m.movie_id join bookings as bk on 
bk.show_id=sh.show_id join theaters as th on th.theater_id=sh.theater_id group by movie_name
order by Total_Theaters desc, Total_Tickets desc;

#18. Find the movies that have an average rating below 4.
select m.title as movie_name, round(avg(rv.rating),1) as Rating from movies as m join reviews as rv 
on m.movie_id=rv.movie_id group by  m.title  having Rating<4 order by Rating desc;

#19. Identify movies that have been screened in more than 50 cities.
select m.title as movie_name, count(th.city) as city_count from movies as m join shows as sh on
sh.movie_id=m.movie_id join theaters as th on th.theater_id=sh.theater_id group by movie_name
having city_count>50 order by city_count desc;

/* C. Theater & Show Performance */
#1.	Identify the top 3 theaters with the highest and lowest bookings.
select * from 
(select th.t_name,th.city,count(booking_id) as total_booking  from bookings as bk join shows as sh on 
bk.show_id=sh.show_id join theaters as th on th.theater_id= sh.theater_id group by th.t_name,th.city 
order by total_booking desc limit 3) as s1
union 
select * from 
(select th.t_name,th.city,count(booking_id) as total_booking  from bookings as bk join shows as sh on 
bk.show_id=sh.show_id join theaters as th on th.theater_id= sh.theater_id group by th.t_name,th.city 
order by total_booking asc limit 3 ) as s2 ;

#2.	Find the most popular time slots for movie shows.
select hour(sh.start_time) as Hours ,count(bk.booking_id) as total_booking from bookings as bk join shows as sh on 
bk.show_id=sh.show_id where hour(sh.start_time)=hour(booking_date) group by start_time order by total_booking desc ;

#3.	Calculate the revenue contribution of each theater.
select th.t_name as theater_name,round( sum(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) as Total_Revenue 
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join theaters as th on th.theater_id=sh.theater_id group by theater_name order by Total_Revenue  desc ;

#4.	Retrieve theaters with frequent low occupancy.
select th.t_name as theater_name,sum(bk.total_tickets)/sum(available_seats)*100 as average_occupancy_rate from 
theaters as th join shows as sh on sh.theater_id=th.theater_id join bookings as bk on bk.show_id=sh.show_id
group by  theater_name order by average_occupancy_rate asc ;

#5.	Identify theaters with the highest ticket prices on average.
select th.t_name as theater_name , round(avg(price_per_ticket),2) as  avg_price from theaters as th join
shows as sh on sh.theater_id=th.theater_id group by theater_name order by  avg_price desc;

#6.	Find theaters where a specific movie is played the most.
select th.t_name as theater_name, m.title as movie_name , count(booking_id) as total_played from theaters as th join shows as sh
on sh.theater_id=th.theater_id join movies as m on m.movie_id=sh.movie_id join bookings as bk on bk.show_id=sh.show_id
group by theater_name,movie_name order by theater_name desc, total_played desc;

#7.	Identify the top 3 theater with the highest occupancy.
select th.t_name as theater_name,sum(bk.total_tickets)/sum(available_seats)*100 as average_occupancy_rate from 
theaters as th join shows as sh on sh.theater_id=th.theater_id join bookings as bk on bk.show_id=sh.show_id
group by  theater_name order by average_occupancy_rate desc limit 3 ;

#8.	Find out which cities have the most active theaters.
select th.city,th.state,count(th.theater_id) as active_theatres from theaters as th where th.theater_id in 
(select theater_id from shows where theater_id=th.theater_id ) group by th.city,th.state order by active_theatres desc;

#9.Find the theaters with the lowest number of bookings in the last 6 months, citywise.
select th.t_name as theater_name, th.city, count(bk.booking_id) as total_booking from theaters as th join shows as sh 
on sh.theater_id=th.theater_id join bookings as bk on bk.show_id=sh.show_id 
group by  theater_name,th.city order by  total_booking asc limit 10;

#10.Identify theaters that have  booked less than 5  shows in the last month, citywise.
select th.t_name as theater_name, th.city, count(bk.booking_id) as total_booking from theaters as th join shows as sh 
on sh.theater_id=th.theater_id join bookings as bk on bk.show_id=sh.show_id where  bk.booking_date>=date_sub(current_date(),interval 1 month)
group by  theater_name,th.city having total_booking<5 order by  total_booking asc;

#11.Identify theaters that have hosted shows for more than 100 different movies.
select th.t_name as theater_name, th.city, count(m.movie_id) as movie_booking from theaters as th join shows as sh 
on sh.theater_id=th.theater_id join movies as m on m.movie_id=sh.movie_id
group by  theater_name,th.city having movie_booking>100 order by  movie_booking desc;

#12.Identify theaters that have hosted shows for movies in multiple languages.
select th.t_name as theater_name, th.city, count(distinct m.m_lang) as movie_language from theaters as th join shows as sh 
on sh.theater_id=th.theater_id join movies as m on m.movie_id=sh.movie_id
group by  theater_name,th.city order by movie_language desc;

#13.Find the top 5 number of movies per theater per month.
select * from 
(select * , rank() over (partition by Months order by total_movies desc ) as Ranks from 
(select monthname(show_date) as Months,th.t_name as theater_name,count(m.movie_id) as total_movies from movies as m join 
shows as sh on sh.movie_id=m.movie_id join theaters as th on th.theater_id=sh.theater_id group by Months,theater_name
order by total_movies  desc) as rnk) as rk where rk.Ranks<=5;

#14.Identify theaters that have hosted shows for more than 5 genres.
select th.t_name as theater_name ,count(distinct m.genre) as movie_genre from theaters as th join shows as sh 
on sh.theater_id=th.theater_id join movies as m on m.movie_id=sh.movie_id
group by  theater_name having movie_genre>5 order by movie_genre desc;

/* D. Booking & Revenue Insights */
#1.	Find the total revenue generated in the last 12 months.
select round( sum(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) as Total_Revenue 
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join theaters as th on th.theater_id=sh.theater_id where  year(booking_date)=year(date_sub(current_date(),interval 1 year ));

#2.	Identify the top 10 users who have spent the most.
select cu.c_name, round( sum(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) as Total_Revenue 
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join c_user as cu on cu.user_id=bk.user_id group by cu.c_name order by Total_Revenue  desc limit 10;

#3.	Determine the 3 most commonly used payment method.
select payment_method, count(payment_id) as total_payment from payments where booking_id in
(select booking_id from bookings) group by payment_method order by total_payment desc limit 3;

#4.	Calculate the average price per booking for Premium seats. 
select  round( avg(sh.price_per_ticket*(1+st.charger/100)) ,3) as Avg_Price from seats as st 
 join shows as sh on st.screen_id=sh.screen_id where st.seat_type='Premium' ;

#5.	Find the average revenue of bookings per year  per Quarter.
select  year(booking_date) as Year,quarter(booking_date) as Quarter ,round( avg(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) 
as Total_Revenue from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id 
group by Year,Quarter order by Year desc ,Total_Revenue desc; 

#6.	Retrieve the number of bookings that were canceled or failed.
select count(*) as Total_Booking from bookings as bk join c_user as cu on cu.user_id=bk.user_id join seats as st on
st.booking_id=bk.booking_id where bk.payment_status in ('Failed','Cancelled');

#7.	Find the total revenue per payment method.
select pm.payment_method,round( sum(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) as Total_Revenue 
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join theaters as th on th.theater_id=sh.theater_id join payments as pm on pm.booking_id=bk.booking_id
group by pm.payment_method order by Total_Revenue  desc ;

#8.	Identify the top 5 cities contributing the most to revenue.
select th.city,th.state,round( sum(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) as Total_Revenue 
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join theaters as th on th.theater_id=sh.theater_id group by th.city,th.state order by Total_Revenue  desc limit 10;

#9.	Determine the percentage of users who book in advance 
select count(cu.c_name)/(select count(*) from c_user)*100 as total_customer from bookings as bk 
join shows as sh on bk.show_id=sh.show_id join c_user as cu on cu.user_id=bk.user_id 
where booking_date<=show_date ;

#10.Find the total revenue generated from VIP seat bookings.
select round( sum(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) as Total_Revenue 
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join theaters as th on th.theater_id=sh.theater_id where st.seat_type='VIP';

#12.Calculate the total revenue lost due to failed transactions.
select round( sum(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) as Total_Revenue_Loss 
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join theaters as th on th.theater_id=sh.theater_id where bk.payment_status='Failed';

#13.Find the average number of tickets booked per state.
select th.state, round(avg(bk.total_tickets),2) as Avg_Booking from theaters as th join shows as sh on sh.theater_id=th.theater_id
join bookings as bk on  bk.show_id=sh.show_id group by th.state order by Avg_Booking desc;

#14.Identify the top 5 movie with the highest revenue.
select  m.title,round( sum(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) as Total_Revenue
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join theaters as th on th.theater_id=sh.theater_id join movies as m on m.movie_id=sh.movie_id group by m.title
order by Total_Revenue desc limit 5;

#15.Calculate the total revenue generated by each state .
select  th.state,round( sum(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) as Total_Revenue
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join theaters as th on th.theater_id=sh.theater_id group by th.state order by Total_Revenue desc;

#16.Identify the top 10 movies with the highest number of bookings.
select m.title, count(booking_id) as total_booking from movies as m join shows as sh on sh.movie_id=m.movie_id
join bookings as bk on bk.show_id=sh.show_id group by  m.title order by total_booking desc limit 10;

#17.Calculate the total revenue generated by each theater.
select  th.t_name,round( sum(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) as Total_Revenue
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join theaters as th on th.theater_id=sh.theater_id group by th.t_name order by Total_Revenue desc;

/* E. Seat Utilization & Pricing Strategy */
#1.	Identify the most frequently booked seat type.
select st.seat_type,count( bk.booking_id) as total_booking from seats as st join bookings as bk on bk.booking_id=st.booking_id
join shows as sh on st.screen_id=sh.screen_id join theaters as th on th.theater_id=sh.theater_id 
group by st.seat_type order by total_booking desc limit 1 ;

#2.	Determine which seat type contributes the most to revenue.
select  st.seat_type,round( sum(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) as Total_Revenue
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join theaters as th on th.theater_id=sh.theater_id group by st.seat_type order by Total_Revenue desc;

#3.	Analyze the pricing variation across theaters and state .
select th.t_name,th.state, round( avg(sh.price_per_ticket*(1+st.charger/100)) ,3) as Avg_Price 
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join theaters as th on th.theater_id=sh.theater_id group by th.t_name,th.state order by th.t_name asc, Avg_Price  desc;

#4.	Determine the impact of price changes on ticket sales based on seats type.theaterwise
select * , round((Avg_Price_After_Seattype -Avg_Price_Before_Seattype)/Avg_Price_Before_Seattype*100,2) as Price_Diff from 
(select th.t_name, round( avg(sh.price_per_ticket) ,3) as Avg_Price_Before_Seattype,
 round( avg(sh.price_per_ticket*(1+st.charger/100)) ,3) as Avg_Price_After_Seattype 
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join theaters as th on th.theater_id=sh.theater_id group by th.t_name order by th.t_name asc ) as Price_Dff;

#5.	Find the no. of movies based on seat type with the seats status is booked or reserved.
select st.seat_type, count(distinct m.movie_id) as total_movie from seats as st join bookings as bk on bk.booking_id=st.booking_id
join shows as sh on sh.show_id=bk.show_id join movies as m on m.movie_id=sh.movie_id where st.status in ('Booked','Reserved')
group by  st.seat_type order by total_movie desc;

#6.	Identify which screen has the booking seats less than 5.
select sc.screen_number,th.t_name,th.city, count(booking_id) as total_booking from bookings as bk join shows as sh 
on sh.show_id=bk.show_id join screens as sc on sc.screen_id=sh.screen_id join theaters as th on 
th.theater_id=sc.theater_id group by sc.screen_number,th.t_name,th.city having total_booking<5
order by total_booking asc;

#7.	Retrieve the status of booking trends yearwise for premium seats.
select year(bk.booking_date) as Year,st.status,  count(bk.booking_id) as booking_trend from bookings as bk join 
shows as sh on bk.show_id=sh.show_id join screens as sc on sh.screen_id=sc.screen_id join theaters as th on
th.theater_id=sc.theater_id join seats as st on st.screen_id=sc.screen_id
where st.seat_type='Premium' group by Year,st.status order by Year desc ,booking_trend desc;

/* F. Payment & Transaction Analysis */
#1.	Find the percentage of failed , refunded and  successful transactions.
select pm.transaction_status,count(bk.booking_id)/(select count(*) from bookings)*100 as percent_trans from payments as pm join
bookings as bk on bk.booking_id=pm.booking_id group by pm.transaction_status order by percent_trans desc;

#2.	Identify refund trends in the system theatre and city wise .
select th.city,th.t_name,count(bk.booking_id) as total_refund from bookings as bk join shows as sh on sh.show_id=bk.show_id
join theaters as th on th.theater_id=sh.theater_id join payments as pm on pm.booking_id=bk.booking_id
where  pm.transaction_status='Refunded' group by th.city,th.t_name order by total_refund desc;

#3.	Determine if certain payment methods have a higher failure rate.
select pm.payment_method,count(bk.booking_id)/(select count(*) from bookings)*100 as total_refund 
from bookings as bk join shows as sh on sh.show_id=bk.show_id
join theaters as th on th.theater_id=sh.theater_id join payments as pm on pm.booking_id=bk.booking_id
where not pm.transaction_status='Success' group by pm.payment_method order by total_refund desc;

#4.	Find the most used successful payment method by high-spending users.
select pm.payment_method,count(cu.user_id) as total_user from c_user as cu join bookings as bk on bk.user_id=cu.user_id
join payments as pm on pm.booking_id=bk.booking_id where pm.transaction_status='Success' group by pm.payment_method
order by total_user desc;

#5.	Identify users who have had multiple failed transactions.
select cu.c_name,count(cu.user_id) as total_user from c_user as cu join bookings as bk on bk.user_id=cu.user_id
join payments as pm on pm.booking_id=bk.booking_id where not pm.transaction_status='Success' group by cu.c_name
order by total_user desc ; 

#6.Find the percentage of  transactions via UPI vs. Credit Card.
select pm.payment_method,count(bk.booking_id)/(select count(*) from bookings)*100 as total_refund 
from bookings as bk join shows as sh on sh.show_id=bk.show_id
join theaters as th on th.theater_id=sh.theater_id join payments as pm on pm.booking_id=bk.booking_id
where  pm.transaction_status='Success' and pm.payment_method in ('UPI','Credit Card')
group by pm.payment_method order by total_refund desc;

#7.Identify the 3 most used successful payment_method .
select pm.payment_method,count(bk.booking_id) as total_payment from bookings as bk join payments as pm
on pm.booking_id=bk.booking_id where pm.transaction_status='Success' group by pm.payment_method 
order by  total_payment desc limit 3;

#8.Find the total revenue lost due to failed payment .
select round( sum(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) as Total_Revenue_Loss 
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join payments as pm on pm.booking_id=bk.booking_id where pm.transaction_status='Failed';

/* G. User Reviews & Sentiment Analysis */
#1.	Retrieve the top 10 highest rating given with its collection .
select m.title, round(avg(rv.rating),1) as Total_Rating, round( sum(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) as Total_Revenue
from c_user as cu join reviews as rv on cu.user_id=rv.user_id join movies as m on m.movie_id=rv.movie_id join bookings as bk on 
bk.user_id=rv.user_id join shows as sh on sh.movie_id=m.movie_id join seats as st on st.booking_id=bk.booking_id
group by m.title order by Total_Rating desc limit 10 ;

#2.	Identify the 3 top-rated and 3 lowest-rated movies.
select * from 
(select m.title, round(avg(rv.rating),1) as Total_Rating from c_user as cu join reviews as rv on cu.user_id=rv.user_id join movies as m
on m.movie_id=rv.movie_id group by m.title order by Total_Rating desc limit 3 ) as top
union all 
select * from 
(select m.title, round(avg(rv.rating),1) as Rating from c_user as cu join reviews as rv on cu.user_id=rv.user_id join movies as m
on m.movie_id=rv.movie_id group by m.title order by Total_Rating asc limit 3 ) as bottom;

#3.	Find the number of users who have given less than 5  moviewise
select m.title,round(avg(rv.rating),1) as Rating, count(cu.user_id) as total_user from c_user as cu join bookings as bk on bk.user_id=cu.user_id
join reviews as rv on rv.user_id=bk.user_id join movies as m on m.movie_id=rv.movie_id group by m.title having Rating<5
order by total_user desc;

#4.	Find out the number of reviews posted per city along with its rating .
select th.city,count(cu.user_id) as total_reviews , round(avg(rv.rating),1) as Rating from c_user as cu join bookings as bk on cu.user_id=bk.user_id
join reviews as rv on rv.user_id=bk.user_id join shows as sh on sh.movie_id=rv.movie_id join theaters as th on th.theater_id=sh.theater_id
group by th.city order by total_reviews desc;

#5.	Calculate the average rating per genre.
select m.genre, round(avg(rv.rating),1) as Rating from c_user as cu join bookings as bk on cu.user_id=bk.user_id
join reviews as rv on rv.user_id=bk.user_id join shows as sh on sh.movie_id=rv.movie_id join theaters as th on th.theater_id=sh.theater_id
join movies as m on m.movie_id=sh.movie_id group by  m.genre;

#6.	Find the total number of reviews per movie genre.
select m.genre,count(cu.user_id) as total_reviews ,round(avg(rv.rating),1) as Rating from c_user as cu join bookings as bk on cu.user_id=bk.user_id
join reviews as rv on rv.user_id=bk.user_id join shows as sh on sh.movie_id=rv.movie_id join theaters as th on th.theater_id=sh.theater_id
join movies as m on m.movie_id=sh.movie_id group by  m.genre order by total_reviews desc;

#7. Find the percentage of movies with an average rating above 7
select count(m.movie_id)/(select count(movie_id) from movies)*100 as percent_movie from c_user as cu join bookings as bk on bk.user_id=cu.user_id
join shows as sh on sh.show_id=bk.show_id join movies as m on m.movie_id=sh.movie_id join reviews as rv on rv.user_id=cu.user_id
where rv.rating>7;

/* Advance Analysis on BookMyShow */
#1.	Find the top 10 users with the highest total spending and their favorite movie genre.
select cu.c_name,m.genre ,round( sum(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) as Total_Revenue
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join theaters as th on th.theater_id=sh.theater_id join movies as m on m.movie_id=sh.movie_id 
join c_user as cu on cu.user_id=bk.user_id group by cu.c_name,m.genre order by Total_Revenue desc limit 10;

#2.	Retrieve top 10 users who booked VIP seats the most and their no. of movies .
select cu.c_name,count(m.movie_id) as total_movie from c_user as cu join bookings as bk on cu.user_id=bk.user_id join shows as sh on 
sh.show_id=bk.show_id join seats as st on st.booking_id=bk.booking_id join movies as m on m.movie_id=sh.movie_id
where st.seat_type='VIP' group by cu.c_name order by total_movie desc limit 10;

#3.	Identify 5 theaters with the highest revenue based on seat type.
select * from 
(select * , rank() over (partition by seat_type order by Total_Revenue desc ) as Ranks from 
(select st.seat_type , th.t_name , round( sum(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) as Total_Revenue
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join theaters as th on th.theater_id=sh.theater_id join movies as m on m.movie_id=sh.movie_id 
join c_user as cu on cu.user_id=bk.user_id group by st.seat_type , th.t_name) as rnk ) as rk where rk.Ranks<=5;

#4.	Retrieve the top 5 cities where premium seats are most booked.
select th.city,count(cu.user_id) as total_bookings from c_user as cu join bookings as bk on cu.user_id=bk.user_id 
join shows as sh on sh.show_id=bk.show_id join theaters as th on th.theater_id=sh.theater_id join seats as st on st.booking_id=bk.booking_id
where st.seat_type='Premium' group by th.city order by total_bookings limit 10;

#5.	Identify city who only book movies in a specific language.
select th.city, count(distinct m.m_lang) as total_language from c_user as cu join bookings as bk on bk.user_id=cu.user_id join shows as sh
on sh.show_id=bk.show_id join movies as m on m.movie_id=sh.movie_id join theaters as th on th.theater_id=sh.theater_id group by th.city
having total_language<1 ;

#6.	Determine which top 3 movie genre is most popular in each city.
select * from
(select *,rank() over (partition by city order by total_booking desc ) as Ranks from
(select th.city,m.genre, count(cu.c_name) as total_booking from c_user as cu join bookings as bk on bk.user_id=cu.user_id join shows as sh
on sh.show_id=bk.show_id join movies as m on m.movie_id=sh.movie_id join theaters as th on th.theater_id=sh.theater_id
group by th.city,m.genre order by total_booking desc)as rnk ) as rk where rk.Ranks<=3;

#7.Find the average transaction amount per city.
select th.city,round( avg(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) as Avg_Revenue
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join theaters as th on th.theater_id=sh.theater_id join movies as m on m.movie_id=sh.movie_id 
join c_user as cu on cu.user_id=bk.user_id group by  th.city order by Avg_Revenue desc ;

#8. Find the percentage of users who have booked both Regular and VIP seats.
select count(cu.user_id)/(select count(*) from bookings)*100 as Percentage_User from c_user as cu join bookings as bk on bk.user_id=cu.user_id
join seats as st on st.booking_id=bk.booking_id where st.seat_type in ('VIP','Regular') ;

#9. Determine the top 3 cities with the highest number of failed transactions theaterwise 
select * from 
(select * , rank() over (partition by t_name order by Total_Revenue desc) as Ranks from
(select th.t_name,th.city,round( sum(bk.total_tickets*sh.price_per_ticket*(1+st.charger/100)) ,3) as Total_Revenue
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join theaters as th on th.theater_id=sh.theater_id join movies as m on m.movie_id=sh.movie_id 
join c_user as cu on cu.user_id=bk.user_id join payments as pm on pm.booking_id=bk.booking_id where pm.transaction_status='Failed'
group by  th.t_name,th.city order by Total_Revenue desc) as Rnk) as rk where rk.Ranks<=3 ;

#10. Identify the top 5 movies that have  high bookings  statewise 
select * from 
(select * , rank() over (partition by state order by Total_Booking desc) as Ranks from
(select th.state,m.title,count(cu.user_id) as Total_Booking
from bookings as bk join seats as st on bk.booking_id=st.booking_id join shows as sh on st.screen_id=sh.screen_id
join theaters as th on th.theater_id=sh.theater_id join movies as m on m.movie_id=sh.movie_id 
join c_user as cu on cu.user_id=bk.user_id join payments as pm on pm.booking_id=bk.booking_id 
group by  th.state,m.title order by Total_Booking desc) as Rnk) as rk where rk.Ranks<=3;



 