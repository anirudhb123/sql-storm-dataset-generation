WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score > 0
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
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
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstModification,
        MAX(ph.CreationDate) AS LastModification,
        STRING_AGG(DISTINCT pht.Name, ', ') AS ChangeTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        pvs.UpVotes,
        pvs.DownVotes,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        phd.FirstModification,
        phd.LastModification,
        phd.ChangeTypes,
        (EXTRACT(EPOCH FROM NOW() - rp.CreationDate) / 3600) AS AgeInHours
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteSummary pvs ON rp.PostID = pvs.PostId
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN 
        PostHistoryDetails phd ON rp.PostID = phd.PostId
)
SELECT 
    fp.*,
    (CASE 
        WHEN fp.UpVotes IS NULL THEN 'No Upvotes' 
        WHEN fp.DownVotes IS NULL THEN 'No Downvotes' 
        ELSE 'Votes Recorded' 
    END) AS VoteStatus,
    (CASE 
        WHEN fp.AgeInHours > 24 THEN 'Old Post'
        WHEN fp.AgeInHours < 1 THEN 'New Post'
        ELSE 'Active Post'
    END) AS PostAgeStatus
FROM 
    FilteredPosts fp
WHERE 
    fp.FirstModification IS NOT NULL
ORDER BY 
    fp.Score DESC NULLS LAST, 
    fp.AgeInHours ASC;

This SQL query includes several complex structures such as CTEs for ranking, voting summaries, user badges, and post history details, combined with various calculations and conditional expressions that produce a detailed report on posts created within the last year. Additionally, it elegantly handles NULL logic and edge cases around post voting and modification history.
