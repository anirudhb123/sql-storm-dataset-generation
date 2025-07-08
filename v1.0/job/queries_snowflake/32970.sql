
WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        p.name AS actor_name,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    WHERE 
        c.movie_id IN (SELECT id FROM aka_title WHERE production_year = 2022) 

    UNION ALL

    SELECT 
        a.person_id,
        p.name AS actor_name,
        ah.level + 1
    FROM 
        cast_info a
    JOIN 
        ActorHierarchy ah ON a.movie_id IN (
            SELECT 
                movie_id 
            FROM 
                cast_info 
            WHERE 
                person_id = ah.person_id
        )
    JOIN 
        aka_name p ON a.person_id = p.person_id
    WHERE 
        ah.level < 5  
),

MovieStats AS (
    SELECT 
        t.title, 
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(COALESCE(m.info_type_id, 0)) AS avg_info_type
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_info m ON t.id = m.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.title, t.production_year
),

TopMovies AS (
    SELECT 
        title, 
        production_year,
        actor_count,
        avg_info_type,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        MovieStats
    WHERE 
        actor_count > 0
),

KeywordSummary AS (
    SELECT 
        t.title AS movie_title,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title
)

SELECT 
    tm.title, 
    tm.production_year,
    tm.actor_count,
    tm.avg_info_type,
    ks.keywords,
    ah.actor_name
FROM 
    TopMovies tm
LEFT JOIN 
    KeywordSummary ks ON tm.title = ks.movie_title
LEFT JOIN 
    ActorHierarchy ah ON tm.actor_count > 1  
WHERE 
    tm.rank <= 10  
ORDER BY 
    tm.actor_count DESC, 
    tm.production_year;
