WITH TaggedPosts AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        to_tsvector(p.Body) AS body_vector
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only Questions
        AND p.Tags IS NOT NULL
), 
TagFrequency AS (
    SELECT 
        unnest(string_to_array(trim(both '<>' from Tags), '><')) AS Tag,
        COUNT(*) AS Frequency
    FROM 
        TaggedPosts
    GROUP BY 
        Tag
),
MostFrequentTags AS (
    SELECT 
        Tag,
        Frequency
    FROM 
        TagFrequency
    ORDER BY 
        Frequency DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2::smallint) AS UpVotes,
        SUM(v.VoteTypeId = 3::smallint) AS DownVotes
    FROM 
        TaggedPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate
),
FinalResults AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ARRAY_AGG(DISTINCT mt.Tag) AS TopTags
    FROM 
        PostStatistics ps
    CROSS JOIN 
        MostFrequentTags mt 
    WHERE 
        ps.Title ILIKE '%' || mt.Tag || '%'
    GROUP BY 
        ps.PostId, ps.Title, ps.CreationDate, ps.CommentCount, ps.UpVotes, ps.DownVotes
)
SELECT 
    PostId,
    Title,
    CreationDate,
    CommentCount,
    UpVotes,
    DownVotes,
    TopTags
FROM 
    FinalResults
ORDER BY 
    UpVotes DESC, CreationDate DESC;
