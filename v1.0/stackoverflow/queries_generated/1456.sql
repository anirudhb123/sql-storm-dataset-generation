WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(b.class = 2)::int, 0) AS SilverBadges,
        COALESCE(SUM(b.class = 3)::int, 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, ',')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 10
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    us.DisplayName,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    COUNT(DISTINCT pt.Tag) AS PopularTags
FROM 
    RankedPosts ps
JOIN 
    Users us ON ps.OwnerUserId = us.Id
LEFT JOIN 
    PostVoteSummary pv ON ps.PostId = pv.PostId
LEFT JOIN 
    PopularTags pt ON pt.Tag = ANY(string_to_array(ps.Title, ' '))
WHERE 
    ps.UserRank <= 3
GROUP BY 
    ps.PostId, us.Id
ORDER BY 
    ps.CreationDate DESC, ps.Score DESC;
