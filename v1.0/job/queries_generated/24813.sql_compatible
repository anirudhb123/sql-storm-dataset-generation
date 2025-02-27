
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_within_year
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
DirectorInfo AS (
    SELECT 
        ci.person_id,
        ak.name AS director_name,
        ak.id AS director_id,
        COUNT(DISTINCT m.id) AS directed_movies_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.id
    WHERE 
        ci.role_id = (SELECT id FROM role_type WHERE role = 'director')
    GROUP BY 
        ci.person_id, ak.name, ak.id
),
TopDirectors AS (
    SELECT 
        director_id,
        director_name,
        directed_movies_count,
        DENSE_RANK() OVER (ORDER BY directed_movies_count DESC) AS director_rank
    FROM 
        DirectorInfo
    WHERE 
        directed_movies_count > 5
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    M.movie_id,
    M.title,
    M.production_year,
    M.total_cast,
    D.director_name,
    D.directed_movies_count,
    K.keyword,
    K.keyword_rank,
    CASE 
        WHEN K.keyword IS NULL THEN 'No Keywords' 
        ELSE 'Has Keywords' 
    END AS keyword_status,
    COALESCE(D.director_rank, 0) AS director_rank,
    CASE 
        WHEN M.rank_within_year <= 3 THEN 'Top 3 of the Year'
        ELSE 'Not Top 3'
    END AS yearly_ranking
FROM 
    RankedMovies M
LEFT JOIN 
    TopDirectors D ON D.director_id = (
        SELECT 
            ci.person_id 
        FROM 
            cast_info ci 
        JOIN 
            aka_title a ON ci.movie_id = a.id 
        WHERE 
            a.id = M.movie_id AND ci.role_id = (SELECT id FROM role_type WHERE role = 'director')
        LIMIT 1
    )
LEFT JOIN 
    MoviesWithKeywords K ON M.movie_id = K.movie_id 
WHERE 
    M.production_year >= 2000 
    AND M.total_cast IS NOT NULL AND M.total_cast > 0
ORDER BY 
    M.production_year DESC, 
    M.total_cast DESC, 
    D.directed_movies_count DESC, 
    K.keyword_rank
OFFSET 5 ROWS 
FETCH NEXT 10 ROWS ONLY;
