WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info AS c
    JOIN 
        RankedMovies AS rm ON c.movie_id = rm.movie_id
    GROUP BY 
        c.person_id
),
TopActors AS (
    SELECT 
        a.person_id,
        ak.name,
        ac.movie_count
    FROM 
        ActorMovieCounts AS ac
    JOIN 
        aka_name AS ak ON ac.person_id = ak.person_id
    WHERE 
        ac.movie_count >= 5
    ORDER BY 
        ac.movie_count DESC
    LIMIT 10
)
SELECT 
    ta.name,
    rm.title,
    rm.production_year,
    COALESCE(mci.note, 'No Note') AS movie_note,
    COALESCE(pi.info, 'No Info') AS actor_info,
    COUNT(DISTINCT mci.company_id) AS production_company_count
FROM 
    TopActors AS ta
JOIN 
    cast_info AS c ON ta.person_id = c.person_id
JOIN 
    RankedMovies AS rm ON c.movie_id = rm.movie_id
LEFT JOIN 
    movie_companies AS mci ON mci.movie_id = rm.movie_id
LEFT JOIN 
    person_info AS pi ON pi.person_id = ta.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'bio')
WHERE 
    rm.year_rank <= 5
GROUP BY 
    ta.name, rm.title, rm.production_year, mci.note, pi.info
ORDER BY 
    production_year DESC, production_company_count DESC;
