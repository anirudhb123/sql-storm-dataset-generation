WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY m.company_id DESC) AS rank_by_year
    FROM 
        title t
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        MAX(CASE WHEN c.nr_order IS NULL THEN 1 ELSE 0 END) AS has_no_order
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
TitleKeywordInfo AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    a.name AS actor_name,
    rm.title AS movie_title,
    rm.production_year,
    ak.movie_count AS total_movies,
    tki.keywords,
    SUM(CASE 
        WHEN ak.movie_count > 5 THEN 1 
        ELSE 0 
    END) OVER (PARTITION BY rm.production_year) AS high_actor_count_indicator,
    CASE 
        WHEN tki.keyword_count IS NULL THEN 'No keywords' 
        ELSE 'Has keywords' 
    END AS keyword_status,
    COALESCE(SUBSTRING(tm.note FROM '%#%'), 'No note') AS movie_note
FROM 
    RankedMovies rm
JOIN 
    ActorMovieCounts ak ON rm.title_id = ak.person_id
JOIN 
    aka_name a ON ak.person_id = a.person_id
LEFT JOIN 
    TitleKeywordInfo tki ON rm.title_id = tki.movie_id
LEFT JOIN 
    movie_info tm ON rm.title_id = tm.movie_id AND tm.info_type_id = (SELECT id FROM info_type WHERE info = 'note' LIMIT 1)
WHERE 
    a.md5sum IS NOT NULL 
    AND rm.rank_by_year <= 5 
ORDER BY 
    rm.production_year DESC, 
    ak.movie_count DESC, 
    a.name;
