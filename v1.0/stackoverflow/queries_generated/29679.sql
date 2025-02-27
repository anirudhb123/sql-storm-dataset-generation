WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
RecentTopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.ViewCount,
        rp.Score,
        rp.CreationDate,
        ARRAY_LENGTH(string_to_array(rp.Tags, '><'), 1) AS TagCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 -- Most recent post for each tag
),
PostsWithBadgeCounts AS (
    SELECT 
        rtp.PostId,
        rtp.Title,
        rtp.Tags,
        rtp.ViewCount,
        rtp.Score,
        rtp.CreationDate,
        rtp.TagCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        RecentTopPosts rtp
    LEFT JOIN 
        Badges b ON b.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = rtp.PostId)
    GROUP BY 
        rtp.PostId, rtp.Title, rtp.Tags, rtp.ViewCount, rtp.Score, rtp.CreationDate, rtp.TagCount
)
SELECT 
    pbbc.PostId,
    pbbc.Title,
    pbbc.Tags,
    pbbc.ViewCount,
    pbbc.Score,
    pbbc.CreationDate,
    pbbc.TagCount,
    pbbc.BadgeCount,
    COALESCE(GREATEST(pbbc.Score, pbbc.BadgeCount),0) AS CompositeScore
FROM 
    PostsWithBadgeCounts pbbc
ORDER BY 
    CompositeScore DESC, 
    pbbc.ViewCount DESC 
LIMIT 10;
