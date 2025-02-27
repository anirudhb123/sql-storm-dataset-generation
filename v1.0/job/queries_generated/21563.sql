WITH RankedTitles AS (
    SELECT 
        a.title AS MovieTitle,
        a.production_year AS ReleaseYear,
        k.keyword AS Genre,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY CHAR_LENGTH(a.title) DESC) AS RankByLength,
        COUNT(DISTINCT mi.info) OVER (PARTITION BY a.id) AS RelatedInfoCount
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON a.id = mi.movie_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
        AND (k.keyword IS NOT NULL OR mi.info IS NOT NULL)
),
TitleInfo AS (
    SELECT 
        rt.MovieTitle,
        rt.ReleaseYear,
        rt.Genre,
        rt.RankByLength,
        rt.RelatedInfoCount,
        COALESCE(ROUND(AVG(m.rating), 2), 0) AS AverageRating
    FROM 
        RankedTitles rt
    LEFT JOIN (
        SELECT 
            movie_id, 
            AVG(rating) AS rating 
        FROM 
            movie_info 
        WHERE 
            info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
        GROUP BY 
            movie_id
    ) m ON rt.MovieTitle = m.movie_id
    GROUP BY 
        rt.MovieTitle, rt.ReleaseYear, rt.Genre, rt.RankByLength, rt.RelatedInfoCount
),
FilteredTitles AS (
    SELECT 
        MovieTitle, 
        ReleaseYear, 
        Genre, 
        RankByLength, 
        AverageRating,
        CASE 
            WHEN AverageRating IS NULL THEN 'No Rating'
            WHEN AverageRating < 5 THEN 'Poor'
            WHEN AverageRating BETWEEN 5 AND 7 THEN 'Average'
            ELSE 'Good'
        END AS RatingCategory
    FROM 
        TitleInfo
    WHERE 
        RankByLength <= 3 -- filter for top 3 longest titles per year
    ORDER BY 
        ReleaseYear DESC, 
        RankByLength ASC
)

SELECT 
    MovieTitle,
    ReleaseYear,
    Genre,
    AverageRating,
    RatingCategory,
    COUNT(*) OVER (PARTITION BY Genre) AS GenreCount
FROM 
    FilteredTitles
WHERE 
    RatingCategory <> 'No Rating' 
    AND ReleaseYear IS NOT NULL
    AND (Genre IS NOT NULL OR MovieTitle IS NOT NULL)
ORDER BY 
    ReleaseYear ASC, 
    AverageRating DESC;
