WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        MAX(m.profit) AS max_profit,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_actors
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        (SELECT movie_id, SUM(profit) AS profit FROM movie_info GROUP BY movie_id) m ON a.id = m.movie_id
    WHERE 
        a.production_year IS NOT NULL 
        AND a.production_year >= 1990
    GROUP BY 
        a.id, a.title, a.production_year
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count,
        AVG(m.profit) AS avg_profit
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN 
        (SELECT movie_id, SUM(profit) AS profit FROM movie_info GROUP BY movie_id) m ON ci.movie_id = m.movie_id
    GROUP BY 
        ak.id, ak.name
),
FamousActors AS (
    SELECT 
        actor_name, 
        movie_count,
        avg_profit,
        RANK() OVER (ORDER BY avg_profit DESC) AS rank_avg_profit
    FROM 
        ActorDetails
    WHERE 
        movie_count > 10
)

SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    CASE 
        WHEN rm.max_profit IS NULL THEN 'Profit data not available' 
        ELSE TO_CHAR(rm.max_profit, 'FM$999,999,999.00') 
    END AS formatted_max_profit,
    COALESCE(fa.actor_name, 'No famous actors') AS famous_actor,
    fa.rank_avg_profit
FROM 
    RankedMovies rm
LEFT JOIN 
    FamousActors fa ON rm.actor_count = fa.movie_count
WHERE 
    rm.rank_by_actors <= 5
ORDER BY 
    rm.production_year DESC,
    rm.actor_count DESC;
