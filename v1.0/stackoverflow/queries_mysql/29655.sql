
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rnk
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.TagName, '>', n.n), '<', -1)) AS TagName
         FROM (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
               UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n) t
    ON FIND_IN_SET(t.TagName, REPLACE(REPLACE(p.Tags, '<', ''), '>', '')) > 0
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, u.DisplayName, pt.Name, p.CreationDate
),
TopPostAuthors AS (
    SELECT 
        rp.OwnerUserId,
        rp.OwnerDisplayName,
        SUM(rp.CommentCount) AS TotalComments,
        SUM(rp.VoteCount) AS TotalVotes,
        GROUP_CONCAT(DISTINCT rp.PostType) AS PostTypes,
        COUNT(rp.PostId) AS PostCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rnk <= 5  
    GROUP BY 
        rp.OwnerUserId, rp.OwnerDisplayName
)
SELECT 
    tpa.OwnerDisplayName,
    tpa.PostCount,
    tpa.TotalComments,
    tpa.TotalVotes,
    tpa.PostTypes,
    GROUP_CONCAT(DISTINCT rp.Tags) AS AllTags
FROM 
    TopPostAuthors tpa
JOIN 
    RankedPosts rp ON tpa.OwnerUserId = rp.OwnerUserId
GROUP BY 
    tpa.OwnerDisplayName, tpa.PostCount, tpa.TotalComments, tpa.TotalVotes, tpa.PostTypes
ORDER BY 
    tpa.TotalVotes DESC, tpa.TotalComments DESC;
