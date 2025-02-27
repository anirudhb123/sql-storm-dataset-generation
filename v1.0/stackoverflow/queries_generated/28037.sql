WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        u.DisplayName AS Author,
        STRING_AGG(t.TagName, ', ') AS Tags,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '> <'))::text) AS TagName) t ON TRUE
    GROUP BY 
        p.Id, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Body,
    rp.Author,
    rp.Tags,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes
FROM 
    RankedPosts rp
WHERE 
    Rank <= 5 AND (UpVotes - DownVotes) > 0
ORDER BY 
    UpVotes DESC, CreationDate ASC;

This SQL query benchmarks string processing through the use of aggregate functions and string manipulation. It creates a Common Table Expression (CTE) that ranks posts by creation date within their types, collects associated tags through string processing, counts comments, and sums up votes to calculate engagement metrics. Finally, it returns the top five posts per type that have more upvotes than downvotes, ordered by popularity.
