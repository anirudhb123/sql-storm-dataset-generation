WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        AVG(CAST(m.info AS FLOAT)) AS average_rating,
        COUNT(m.movie_id) AS total_movies
    FROM 
        title t
    LEFT JOIN 
        movie_info m ON t.id = m.movie_id 
    WHERE 
        m.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
    GROUP BY 
        t.id, t.title
), 
ActorParticipation AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS titles
    FROM 
        cast_info c 
    JOIN 
        aka_name a ON c.person_id = a.person_id 
    JOIN 
        title t ON c.movie_id = t.id 
    GROUP BY 
        a.person_id
),
CompanyParticipation AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies_involved,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FinalBenchmark AS (
    SELECT 
        rt.title,
        rt.average_rating,
        ap.movie_count AS actor_movie_count,
        ap.titles AS actor_titles,
        cp.companies_involved,
        cp.total_companies
    FROM 
        RankedTitles rt
    LEFT JOIN 
        ActorParticipation ap ON ap.movie_count > 0 
    LEFT JOIN 
        CompanyParticipation cp ON cp.movie_id = rt.title_id
    WHERE 
        rt.average_rating > 7.0
)
SELECT 
    title, 
    average_rating, 
    actor_movie_count, 
    actor_titles, 
    companies_involved, 
    total_companies
FROM 
    FinalBenchmark
ORDER BY 
    average_rating DESC, 
    actor_movie_count DESC;
