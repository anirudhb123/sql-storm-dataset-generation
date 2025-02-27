WITH RecursiveFilmography AS (
    SELECT 
        a.person_id,
        a.name AS actor_name,
        a.md5sum AS actor_md5,
        c.movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS release_rank
    FROM 
        aka_name a 
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL

    UNION ALL 

    SELECT 
        a.person_id,
        a.name AS actor_name,
        a.md5sum AS actor_md5,
        c.movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS release_rank
    FROM 
        aka_name a 
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NULL
),
DistinctActors AS (
    SELECT DISTINCT 
        person_id, 
        actor_name, 
        actor_md5 
    FROM 
        RecursiveFilmography 
    WHERE 
        release_rank <= 5
),
TrendingMovies AS (
    SELECT 
        d.actor_name,
        d.actor_md5,
        COUNT(r.movie_id) AS movie_count,
        STRING_AGG(DISTINCT r.movie_title, ', ') AS movies
    FROM 
        RecursiveFilmography r
    JOIN 
        DistinctActors d ON r.actor_md5 = d.actor_md5
    GROUP BY 
        d.actor_name, d.actor_md5
    HAVING 
        COUNT(r.movie_id) > 1
)
SELECT 
    t.actor_name,
    t.movie_count,
    t.movies,
    COALESCE(m.ID, -1) AS movie_id,
    COALESCE(info.info, 'N/A') AS additional_info,
    CASE 
        WHEN m.company_id IS NULL THEN 
            'No production company'
        ELSE 
            c.name 
    END AS production_company
FROM 
    TrendingMovies t
LEFT JOIN 
    movie_companies m ON m.movie_id = (SELECT movie_id 
                                         FROM complete_cast 
                                         WHERE subject_id = (SELECT id FROM aka_name WHERE md5sum = t.actor_md5) 
                                         LIMIT 1)
LEFT JOIN 
    company_name c ON m.company_id = c.id
LEFT JOIN 
    movie_info info ON info.movie_id = m.movie_id AND info.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office' LIMIT 1)
WHERE 
    t.movie_count > 2 
    AND t.actor_name LIKE 'A%' 
ORDER BY 
    t.movie_count DESC, 
    t.actor_name ASC;
