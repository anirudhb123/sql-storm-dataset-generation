WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Score, 
        p.CreationDate, 
        COALESCE(UPM.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(DM.DownVoteCount, 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS UpVoteCount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 2 
        GROUP BY 
            PostId
    ) UPM ON UPM.PostId = p.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS DownVoteCount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 3 
        GROUP BY 
            PostId
    ) DM ON DM.PostId = p.Id
)
SELECT 
    u.DisplayName,
    STRING_AGG(t.TagName, ', ') AS Tags,
    SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
    rp.Title,
    rp.Score,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.CreationDate
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Tags t ON t.Id = ANY(STRING_TO_ARRAY(p.Tags, ','))
LEFT JOIN 
    Badges b ON b.UserId = u.Id
JOIN 
    RankedPosts rp ON rp.Id = p.Id AND rp.rn = 1
GROUP BY 
    u.DisplayName, rp.Title, rp.Score, rp.UpVoteCount, rp.DownVoteCount, rp.CreationDate
HAVING 
    SUM(b.Class) > 0 
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 100;
