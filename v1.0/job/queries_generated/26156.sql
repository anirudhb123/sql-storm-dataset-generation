WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title AS t
    JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    JOIN 
        cast_info AS c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
ActorStats AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(c.movie_id) AS movie_count
    FROM 
        aka_name AS a
    JOIN 
        cast_info AS c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
),
HighProfileActors AS (
    SELECT 
        name,
        movie_count
    FROM 
        ActorStats
    WHERE 
        movie_count > 5
),
KeywordStats AS (
    SELECT 
        m.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title AS m
    JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    GROUP BY 
        m.id
),
TopKeywords AS (
    SELECT 
        m.title,
        COUNT(mk.keyword_id) AS count_keywords
    FROM 
        aka_title AS m
    JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    GROUP BY 
        m.title
    ORDER BY 
        count_keywords DESC
    LIMIT 10
)

SELECT 
    rm.title,
    rm.production_year,
    hm.name AS high_profile_actor,
    tk.title AS top_keyword_title,
    tk.count_keywords
FROM 
    RankedMovies AS rm
JOIN 
    HighProfileActors AS hm ON (hm.movie_count > 5 AND rm.movie_id IN (
        SELECT ci.movie_id
        FROM cast_info AS ci
        JOIN aka_name AS an ON ci.person_id = an.person_id
        WHERE an.name = hm.name
    ))
JOIN 
    TopKeywords AS tk ON rm.title = tk.title
WHERE 
    rm.rank = 1
ORDER BY 
    rm.production_year DESC, tk.count_keywords DESC;
This query performs a series of common table expressions (CTEs) to organize and analyze data from several tables in a rich database schema for movie information. It ranks movies by production year based on the number of cast members, identifies high-profile actors who have featured in more than five movies, and counts keywords associated with movies. Finally, it pulls together the top-ranked movies alongside noteworthy actors and their associated keywords for insightful benchmarking of string processing in this large dataset.
