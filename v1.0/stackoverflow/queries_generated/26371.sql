WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(c.Id) AS CommentCount, 
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- only questions
        AND p.CreationDate >= NOW() - INTERVAL '30 days' -- within the last 30 days
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Body, 
        rp.Tags, 
        rp.CommentCount, 
        rp.UpVoteCount, 
        rp.DownVoteCount,
        (rp.UpVoteCount - rp.DownVoteCount) AS Score,
        LENGTH(rp.Body) - LENGTH(REPLACE(rp.Body, ' ', '')) + 1 AS WordCount -- count words in Body
    FROM 
        RankedPosts rp
    WHERE 
        rp.RowNum = 1 -- ensure to pick the latest entry for each post
)
SELECT 
    fp.PostId, 
    fp.Title, 
    fp.CommentCount,
    fp.Score,
    fp.WordCount,
    ARRAY(SELECT 
              DISTINCT TRIM(UNNEST(string_to_array(fp.Tags, '<>'))) AS Tag 
           FROM 
              unnest(string_to_array(fp.Tags, '<>')) AS Tag)
    AS DistinctTags 
FROM 
    FilteredPosts fp
WHERE 
    fp.Score > 0 
ORDER BY 
    fp.Score DESC, 
    fp.CommentCount DESC
LIMIT 10;

This query benchmarks string processing by retrieving the most engaged questions (above a certain score and filtered by a time frame) while performing multiple string manipulations on the tags. It computes several metrics, including the number of comments, upvotes, downvotes, a word count for the post body, and the distinct tags associated with each question.
