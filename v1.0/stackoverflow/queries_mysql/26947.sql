
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByScore,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS TagsList
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '> <', n.n), '> <', -1)) AS TagName
         FROM Posts p
         JOIN (SELECT a.N + b.N * 10 + 1 n
               FROM (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 
                     UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 
                     UNION SELECT 8 UNION SELECT 9) a
               CROSS JOIN (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 
                           UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 
                           UNION SELECT 8 UNION SELECT 9) b) n
         WHERE n.n <= 1 + (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '> <', ''))) 
        ) AS tagArray ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tagArray.TagName
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01 12:34:56', INTERVAL 1 YEAR)
    GROUP BY 
        p.Id, pt.Name, p.Title, p.CreationDate, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        TagsList
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 5  
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.TagsList,
    ua.DisplayName AS PostOwner,
    ua.TotalPosts AS TotalPostsByOwner,
    ua.TotalUpVotes AS TotalUpVotesByOwner,
    ua.TotalDownVotes AS TotalDownVotesByOwner
FROM 
    TopPosts tp
JOIN 
    UserActivity ua ON tp.PostId IN (
        SELECT 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = ua.UserId
    )
ORDER BY 
    tp.ViewCount DESC, 
    tp.CreationDate DESC;
