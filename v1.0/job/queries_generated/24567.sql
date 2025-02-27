WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rn
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        COALESCE(c.cn, 'Unknown Company') AS company_name,
        COALESCE(ARRAY_AGG(DISTINCT k.keyword) FILTER (WHERE k.keyword IS NOT NULL), '{}') AS keywords,
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        SUM(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS not_null_notes_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        rm.movie_id, rm.title, c.cn
),
FilteredMovies AS (
    SELECT *
    FROM MovieDetails
    WHERE 
        num_cast_members > 3 AND 
        (NOT (keywords @> ARRAY['Action']) OR keywords @> ARRAY['Drama']) 
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.company_name,
    fm.keywords,
    fm.num_cast_members,
    fm.not_null_notes_count,
    CASE 
        WHEN fm.not_null_notes_count > 5 THEN 'Highly Noted'
        WHEN fm.not_null_notes_count BETWEEN 1 AND 5 THEN 'Moderately Noted'
        ELSE 'Poorly Noted'
    END AS note_quality,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = fm.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')) AS has_box_office_info
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, fm.title ASC;

### Query Explanation:
1. **CTE `RankedMovies`**: This Common Table Expression (CTE) ranks movies by title within their production year.
2. **CTE `MovieDetails`**: It aggregates movie information, including company names, associated keywords, number of cast members, and counts of non-null notes.
3. **`FilteredMovies` CTE**: It filters movies that have more than three cast members and either do not include 'Action' in their keywords or do include 'Drama'.
4. **Final Selection**: Selects relevant details, performs a case analysis for note quality, and counts the number of specific info types (Box Office) for each movie.
5. **ORDER BY**: The results are ordered by production year descending and title ascending, ensuring that the latest movies appear first.
