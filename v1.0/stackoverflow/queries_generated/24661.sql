WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS CloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        Users
),
HighReputationUsers AS (
    SELECT 
        u.UserId,
        u.Reputation,
        u.ReputationRank,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        UserReputation u
    LEFT JOIN 
        Badges b ON u.UserId = b.UserId
    WHERE 
        u.ReputationRank <= 100
    GROUP BY 
        u.UserId, u.Reputation, u.ReputationRank
),
FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.TagCount,
        COALESCE(CAST(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3) AS INT), 0) AS VoteBalance, 
        RANK() OVER (ORDER BY COALESCE(CAST(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3) AS INT), 0) DESC) AS VoteRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.TagCount
),
PostSummary AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.VoteBalance,
        rp.CloseDate,
        rp.ReopenDate,
        CASE 
            WHEN rp.CloseReopenCount > 1 THEN 'Reopened Multiple Times'
            WHEN rp.CloseDate IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus,
        hp.UserId AS AwardedUserId,
        hp.BadgeCount
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        RecursivePostHistory rp ON fp.PostId = rp.PostId
    LEFT JOIN 
        HighReputationUsers hp ON hp.UserId = (SELECT TOP 1 UserId FROM Votes WHERE PostId = fp.PostId ORDER BY CreationDate DESC)
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.VoteBalance,
    ps.PostStatus,
    ps.CloseDate,
    ps.ReopenDate,
    ps.AwardedUserId,
    ps.BadgeCount,
    (CASE 
        WHEN ps.CloseDate IS NOT NULL AND ps.ReopenDate IS NOT NULL THEN 'Closed and Reopened'
        WHEN ps.CloseDate IS NULL AND ps.ReopenDate IS NULL THEN 'Never Closed'
        ELSE 'Either Closed or Reopened'
    END) AS CloseReopenStatus,
    (SELECT STRING_AGG(Tags.TagName, ', ')
     FROM Posts p 
     JOIN STRING_SPLIT(p.Tags, ',') AS Tags ON p.Id = ps.PostId) AS TagsList
FROM 
    PostSummary ps
WHERE 
    ps.VoteBalance > 0
ORDER BY 
    ps.VoteBalance DESC, 
    ps.BadgeCount DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
