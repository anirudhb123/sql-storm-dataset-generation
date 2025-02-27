WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS Tag
    FROM 
        Posts 
    WHERE 
        PostTypeId = 1
),
TagPopularity AS (
    SELECT 
        Tag, 
        COUNT(*) AS UsageCount
    FROM 
        PopularTags
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    LIMIT 5
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class), 0) AS BadgeCount,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    tr.Tag,
    ur.DisplayName,
    ur.Reputation,
    ur.BadgeCount
FROM 
    RankedPosts rp
JOIN 
    TagPopularity tr ON rp.Title ILIKE '%' || tr.Tag || '%'
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
WHERE 
    rp.RankByUser <= 5
ORDER BY 
    rp.ViewCount DESC, rp.CreationDate DESC
LIMIT 100;

