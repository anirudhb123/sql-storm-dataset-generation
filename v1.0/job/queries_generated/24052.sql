WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast_count,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorsWithRoles AS (
    SELECT 
        a.id AS person_id, 
        a.name,
        c.role_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type c ON ci.role_id = c.id
    GROUP BY 
        a.id, a.name, c.role_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 3
),
PopularKeywords AS (
    SELECT
        mk.keyword,
        COUNT(mk.movie_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.keyword
    HAVING 
        COUNT(mk.movie_id) > 5
),
MovieStats AS (
    SELECT 
        m.movie_id,
        mp.production_year,
        COALESCE(kw.keyword, 'No Keyword') AS keyword,
        COALESCE(SUM(mi.info_type_id), 0) AS total_info_types,
        RANK() OVER (PARTITION BY mp.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS cast_rank
    FROM 
        complete_cast m
    LEFT JOIN 
        RankedMovies mp ON m.movie_id = mp.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        PopularKeywords kw ON mk.keyword = kw.keyword
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    LEFT JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    GROUP BY 
        m.movie_id, mp.production_year, kw.keyword
    HAVING 
        SUM(mi.info_type_id) IS NOT NULL
)
SELECT 
    ms.movie_id,
    ms.production_year,
    ms.keyword,
    ms.total_info_types,
    ms.cast_rank,
    a.name AS actor_name,
    a.movie_count AS actor_movie_count
FROM 
    MovieStats ms
JOIN 
    ActorsWithRoles a ON ms.movie_id IN (
        SELECT ci.movie_id 
        FROM cast_info ci 
        WHERE ci.person_id = a.person_id
    )
WHERE 
    ms.cast_rank <= 5 
ORDER BY 
    ms.production_year DESC, 
    ms.cast_rank ASC, 
    a.actor_movie_count DESC;
