WITH TopMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast_members,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title ak
    JOIN 
        title m ON ak.movie_id = m.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
    ORDER BY 
        total_cast_members DESC
    LIMIT 10
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS production_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast_members,
    tm.aka_names,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mc.production_companies, 'No companies') AS production_companies
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON tm.movie_id = mc.movie_id;

This SQL query does the following:
1. It defines a Common Table Expression (CTE) to identify the top 10 movies since 2000 based on the number of unique cast members.
2. It aggregates the alternative names associated with those movies.
3. It defines another CTE to gather unique keywords for the same set of movies.
4. It defines a third CTE to list the production companies for these movies.
5. Finally, it joins these CTEs to produce a final output displaying the movie title, production year, total cast members, alternative names, keywords, and production companies.
