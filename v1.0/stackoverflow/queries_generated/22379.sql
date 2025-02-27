WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
),

PostVoteStats AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId IN (10, 12) THEN 1 END) AS DeleteVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),

TagPostCounts AS (
    SELECT 
        t.Id AS TagId,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id
),

UserBadgeCounts AS (
    SELECT
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    COALESCE(pvs.DeleteVotes, 0) AS DeleteVotes,
    COALESCE(tpc.PostCount, 0) AS TagPostCount,
    u.DisplayName AS UserDisplayName,
    ubc.GoldBadges,
    ubc.SilverBadges,
    ubc.BronzeBadges
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteStats pvs ON rp.PostId = pvs.PostId
LEFT JOIN 
    Tags t ON t.TagId = ANY(string_to_array(rp.Tags, '>'))
LEFT JOIN 
    TagPostCounts tpc ON t.Id = tpc.TagId
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadgeCounts ubc ON u.Id = ubc.UserId
WHERE 
    rp.Rank <= 5
    AND rp.ViewCount > 100
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
