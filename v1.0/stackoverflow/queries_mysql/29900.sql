
WITH CombinedPostData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        (SELECT COUNT(CASE WHEN b.Class = 1 THEN 1 ELSE NULL END) FROM Badges b WHERE b.UserId = p.OwnerUserId) AS GoldBadges,
        (SELECT COUNT(CASE WHEN b.Class = 2 THEN 1 ELSE NULL END) FROM Badges b WHERE b.UserId = p.OwnerUserId) AS SilverBadges,
        (SELECT COUNT(CASE WHEN b.Class = 3 THEN 1 ELSE NULL END) FROM Badges b WHERE b.UserId = p.OwnerUserId) AS BronzeBadges
    FROM 
        Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName, u.Reputation
),

PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName
    FROM 
        Posts p
    INNER JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
         SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1
),

TagStatistics AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        PostTagCounts pt
        JOIN Users u ON pt.PostId = u.Id
    GROUP BY 
        TagName
)

SELECT 
    cp.PostId,
    cp.Title,
    cp.Body,
    cp.CreationDate,
    cp.OwnerDisplayName,
    cp.Reputation,
    cp.CommentCount,
    cp.UpVotes,
    cp.DownVotes,
    cp.GoldBadges,
    cp.SilverBadges,
    cp.BronzeBadges,
    pt.TagName,
    ts.PostCount,
    ts.AvgReputation
FROM 
    CombinedPostData cp
JOIN 
    PostTagCounts pt ON cp.PostId = pt.PostId
JOIN 
    TagStatistics ts ON pt.TagName = ts.TagName
WHERE 
    cp.Reputation > 1000
ORDER BY 
    cp.CreationDate DESC, 
    ts.PostCount DESC
LIMIT 50;
