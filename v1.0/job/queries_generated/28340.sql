WITH RankedTitles AS (
    SELECT 
        a.title AS Movie_Title,
        a.production_year AS Production_Year,
        a.imdb_index AS IMDb_Index,
        COUNT(DISTINCT c.person_id) AS Cast_Count,
        STRING_AGG(DISTINCT ak.name, ', ') AS Actors_Names,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS Rank_by_Cast
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        AND a.production_year > 2000
    GROUP BY 
        a.id, a.title, a.production_year, a.imdb_index
), 
TopMovies AS (
    SELECT 
        Movie_Title, 
        Production_Year, 
        IMDb_Index, 
        Cast_Count,
        Rank_by_Cast
    FROM 
        RankedTitles
    WHERE 
        Rank_by_Cast <= 5
)
SELECT 
    tm.Movie_Title,
    tm.Production_Year,
    tm.IMDb_Index,
    tm.Cast_Count,
    TRIM(UPPER(tm.Movie_Title)) AS Uppercase_Title,
    REPLACE(tm.Movie_Title, ' ', '-') AS Title_With_Dashes,
    SUBSTRING(tm.Movie_Title FROM 1 FOR 20) AS Short_Title,
    COALESCE(SUM(mk.keyword LIKE '%drama%'), 0) AS Drama_Keywords,
    COALESCE(SUM(mk.keyword LIKE '%comedy%'), 0) AS Comedy_Keywords
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON mk.movie_id IN (SELECT movie_id FROM aka_title WHERE title = tm.Movie_Title)
GROUP BY 
    tm.Movie_Title, tm.Production_Year, tm.IMDb_Index, tm.Cast_Count
ORDER BY 
    tm.Production_Year DESC, tm.Cast_Count DESC;
