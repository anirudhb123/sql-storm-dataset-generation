WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        c.name AS cast_member,
        c.nr_order,
        t.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS cast_rank
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        title t ON a.id = t.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND c.nr_order <= 5
),
FilteredRankedMovies AS (
    SELECT 
        movie_title,
        string_agg(cast_member, ', ') AS cast_members,
        production_year,
        string_agg(DISTINCT movie_keyword, ', ') AS keywords
    FROM 
        RankedMovies
    GROUP BY 
        movie_title, production_year
    ORDER BY 
        production_year DESC
)
SELECT 
    movie_title,
    cast_members,
    production_year,
    keywords
FROM 
    FilteredRankedMovies
WHERE 
    position('action' IN keywords) > 0
    OR position('drama' IN keywords) > 0
ORDER BY 
    production_year DESC, movie_title;
