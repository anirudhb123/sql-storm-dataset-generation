-- Performance Benchmarking Query for StackOverflow Schema

-- This query measures the performance by retrieving and aggregating data from multiple tables 
-- to assess the network and database capabilities of the StackOverflow schema.

WITH PostData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filtering posts created in the last year
    GROUP BY 
        p.Id, u.DisplayName
),
TagData AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts pt ON pt.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.Id, t.TagName
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.AnswerCount,
    pd.CommentCount,
    pd.VoteCount,
    td.TagName,
    td.PostCount
FROM 
    PostData pd
LEFT JOIN 
    TagData td ON pd.PostId IN (SELECT UNNEST(string_to_array(pd.Tags, ',')))
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
LIMIT 100; -- Display the top 100 posts for benchmarking
