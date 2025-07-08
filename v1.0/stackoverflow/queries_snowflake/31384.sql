
WITH RECURSIVE UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        WebsiteUrl,
        Location,
        AboutMe,
        1 AS Level
    FROM 
        Users
    WHERE 
        Reputation > 1000

    UNION ALL

    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        u.WebsiteUrl,
        u.Location,
        u.AboutMe,
        ur.Level + 1
    FROM 
        Users u
    JOIN 
        UserReputation ur ON u.Reputation < ur.Reputation
    WHERE 
        ur.Level < 5
)

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
    LISTAGG(DISTINCT t.TagName, ', ') AS Tags,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 6) THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    (SELECT AVG(Reputation) FROM Users WHERE CreationDate < p.CreationDate) AS AvgReputationBeforePostCreation
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT 
        TRIM(SPLIT_PART(tag, ',', seq)) AS TagName
     FROM 
        (SELECT p.Tags, ROW_NUMBER() OVER () AS seq 
         FROM Posts p) AS tags_sequenced
     CROSS JOIN 
        (SELECT seq4() AS seq FROM TABLE(GENERATOR(ROWCOUNT => 100))) AS seq_table
     WHERE 
        seq <= ARRAY_SIZE(SPLIT(p.Tags, ',')) ) t ON TRUE
WHERE 
    p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01')
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, u.Reputation
ORDER BY 
    p.Score DESC, 
    p.Title ASC
LIMIT 50;
