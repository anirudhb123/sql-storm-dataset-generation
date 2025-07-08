
WITH RankedMovies AS (
    SELECT 
        a.title AS Movie_Title,
        a.production_year AS Production_Year,
        COUNT(DISTINCT c.person_id) AS Actor_Count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS Yearly_Rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
SelectedMovies AS (
    SELECT 
        Movie_Title, 
        Production_Year, 
        Actor_Count
    FROM 
        RankedMovies
    WHERE 
        Yearly_Rank <= 5
),
GenreMovieCount AS (
    SELECT 
        k.keyword AS Genre,
        COUNT(DISTINCT m.id) AS Movie_Count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        k.keyword
),
GenreMapping AS (
    SELECT 
        m.title AS Movie_Title,
        k.keyword AS Genre
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
)
SELECT 
    sm.Movie_Title,
    sm.Production_Year,
    sm.Actor_Count,
    COALESCE(gm.Movie_Count, 0) AS Genre_Count
FROM 
    SelectedMovies sm
LEFT JOIN 
    GenreMovieCount gm ON gm.Genre = (
        SELECT 
            Genre
        FROM 
            GenreMapping
        WHERE 
            Movie_Title = sm.Movie_Title
        LIMIT 1
    )
ORDER BY 
    sm.Production_Year DESC, 
    sm.Actor_Count DESC;
