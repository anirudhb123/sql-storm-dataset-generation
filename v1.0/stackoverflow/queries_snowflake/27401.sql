
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostTagCounts AS (
    SELECT 
        TRIM(REGEXP_SUBSTR(p.Tags, '[^><]+', 1, seq)) AS Tag,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p,
        (SELECT ROW_NUMBER() OVER () AS seq FROM TABLE(GENERATOR(ROWCOUNT => 100))) s
    WHERE 
        p.PostTypeId = 1 AND
        seq <= SPLIT_COUNT(p.Tags, '><')
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        PostTagCounts
    WHERE 
        PostCount > 10
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    u.DisplayName AS OwnerName,
    us.UpVotes,
    us.DownVotes,
    us.BadgeCount,
    tt.Tag,
    tt.PostCount
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserScores us ON us.UserId = rp.OwnerUserId
JOIN 
    TopTags tt ON tt.Tag IN (TRIM(REGEXP_SUBSTR(rp.Tags, '[^><]+', 1, seq)))
WHERE 
    rp.Rank = 1 
ORDER BY 
    tt.PostCount DESC, rp.Score DESC;
