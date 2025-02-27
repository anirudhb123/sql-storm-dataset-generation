WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts rp ON p.ParentId = rp.PostId
),
PostVoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 10 THEN 1 END) AS DeletionVotes
    FROM 
        Votes
    GROUP BY 
        PostId
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
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        COALESCE(us.Reputation, 0) AS UserReputation,
        COALESCE(pvs.UpVotes, 0) AS UpVotes,
        COALESCE(pvs.DownVotes, 0) AS DownVotes,
        COALESCE(pvs.DeletionVotes, 0) AS DeletionVotes,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
    FROM 
        RecursivePosts rp
    LEFT JOIN 
        Users us ON rp.OwnerUserId = us.Id
    LEFT JOIN 
        PostVoteSummary pvs ON rp.PostId = pvs.PostId
    LEFT JOIN 
        UserBadges ub ON us.Id = ub.UserId
)
SELECT 
    pd.Title,
    pd.Score,
    pd.UserReputation,
    pd.UpVotes,
    pd.DownVotes,
    pd.DeletionVotes,
    pd.GoldBadges + pd.SilverBadges + pd.BronzeBadges AS TotalBadges,
    CASE 
        WHEN pd.UpVotes > pd.DownVotes THEN 'Positive'
        WHEN pd.UpVotes < pd.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    COUNT(c.Id) AS CommentCount
FROM 
    PostDetails pd
LEFT JOIN 
    Comments c ON pd.PostId = c.PostId
GROUP BY 
    pd.Title, pd.Score, pd.UserReputation, pd.UpVotes, pd.DownVotes, pd.DeletionVotes, pd.GoldBadges, pd.SilverBadges, pd.BronzeBadges
ORDER BY 
    pd.Score DESC, pd.UserReputation DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
