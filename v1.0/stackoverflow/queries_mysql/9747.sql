
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        @rank := @rank + 1 AS Rank
    FROM 
        RecentPosts rp,
        (SELECT @rank := 0) r
    ORDER BY 
        rp.UpVotes - rp.DownVotes DESC
)
SELECT 
    p.Title,
    p.OwnerDisplayName,
    rp.CreationDate,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes,
    pt.Name AS PostTypeName
FROM 
    TopPosts p
    JOIN PostTypes pt ON (
        CASE 
            WHEN p.PostId IN (SELECT PostId FROM Posts WHERE PostTypeId = 1) THEN 1 
            WHEN p.PostId IN (SELECT PostId FROM Posts WHERE PostTypeId = 2) THEN 2 
            ELSE NULL 
        END
    ) = pt.Id
    JOIN RecentPosts rp ON rp.PostId = p.PostId
WHERE 
    p.Rank <= 10
ORDER BY 
    p.Rank;
