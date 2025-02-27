WITH RECURSIVE UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN v.VoteTypeId IN (8, 9) THEN v.BountyAmount ELSE 0 END) AS BountyAmount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(p.Tags, '>')) AS TagName) AS t ON TRUE
    WHERE 
        p.PostTypeId = 1 -- Only on Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AcceptedAnswerId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
VoteStatistics AS (
    SELECT 
        ud.UserId,
        ud.DisplayName,
        uvc.Upvotes,
        uvc.Downvotes,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        Users ud
    JOIN 
        UserVoteCounts uvc ON ud.Id = uvc.UserId
    LEFT JOIN 
        UserBadges ub ON ud.Id = ub.UserId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.CommentCount,
    pd.CloseCount,
    STRING_AGG(DISTINCT pd.Tags, ', ') AS TagList,
    vs.DisplayName AS TopVoter,
    vs.Upvotes,
    vs.Downvotes,
    COALESCE(vs.GoldBadges, 0) AS GoldBadges,
    COALESCE(vs.SilverBadges, 0) AS SilverBadges,
    COALESCE(vs.BronzeBadges, 0) AS BronzeBadges
FROM 
    PostDetails pd
JOIN 
    Votes v ON pd.PostId = v.PostId
JOIN 
    VoteStatistics vs ON v.UserId = vs.UserId
WHERE 
    pd.ViewCount > 1000 
    AND pd.Score > 10
GROUP BY 
    pd.PostId, pd.Title, pd.CreationDate, pd.ViewCount, pd.Score, pd.CommentCount, pd.CloseCount, vs.DisplayName, vs.Upvotes, vs.Downvotes
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
LIMIT 100;
