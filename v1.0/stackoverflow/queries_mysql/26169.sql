
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.Id) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT tag FROM Posts p CROSS JOIN (
            SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) tag
            FROM (
                SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
                UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
            WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
        ) AS tag) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag.tag
    GROUP BY 
        p.Id
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        p.Id
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(ptc.TagCount, 0) AS TagCount,
        COALESCE(pv.Upvotes, 0) AS Upvotes,
        COALESCE(pv.Downvotes, 0) AS Downvotes,
        pv.TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        PostTagCounts ptc ON p.Id = ptc.PostId
    LEFT JOIN 
        PostVotes pv ON p.Id = pv.PostId
),
TopActivePosts AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.CreationDate,
        pa.TagCount,
        pa.Upvotes,
        pa.Downvotes,
        pa.TotalVotes,
        @rank := @rank + 1 AS Rank
    FROM 
        PostActivity pa, (SELECT @rank := 0) AS r
    ORDER BY 
        pa.TotalVotes DESC, pa.CreationDate DESC
)
SELECT 
    tap.PostId,
    tap.Title,
    tap.CreationDate,
    tap.TagCount,
    tap.Upvotes,
    tap.Downvotes,
    tap.TotalVotes
FROM 
    TopActivePosts tap
WHERE 
    tap.Rank <= 10
ORDER BY 
    tap.TotalVotes DESC, tap.CreationDate DESC;
