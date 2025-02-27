WITH UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CASE 
            WHEN Reputation IS NULL THEN 'Unknown Reputation'
            WHEN Reputation < 1000 THEN 'Novice'
            WHEN Reputation < 10000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM Users
),
PostUserAssociation AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.PostTypeId,
        p.CreationDate,
        CASE
            WHEN p.CreationDate < NOW() - INTERVAL '1 year' THEN 'Legacy Post'
            WHEN p.CreationDate >= NOW() - INTERVAL '1 year' AND p.CreationDate < NOW() - INTERVAL '1 month' THEN 'Recent Post'
            ELSE 'Fresh Post'
        END AS PostRecency,
        COALESCE(p.AnswerCount, 0) AS AnswerCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
),
PostStatistics AS (
    SELECT 
        pua.PostId,
        pua.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY pua.PostId ORDER BY pua.CreationDate DESC) AS Rn
    FROM PostUserAssociation pua
    LEFT JOIN Comments c ON pua.PostId = c.PostId
    LEFT JOIN Votes v ON pua.PostId = v.PostId AND v.VoteTypeId IN (8, 9)  -- Bounty Start or End
    GROUP BY pua.PostId, pua.OwnerDisplayName
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS MaxCloseDate,
        STRING_AGG(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.Comment ELSE NULL END, '; ') AS CloseReasons
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11)  -- Close or Reopen
),
PostWithHistory AS (
    SELECT 
        ps.PostId,
        ps.OwnerDisplayName,
        ps.CommentCount,
        ps.TotalBounty,
        ch.CloseDate,
        ch.CloseReasons,
        CASE 
            WHEN ch.CloseDate IS NOT NULL AND ch.MaxCloseDate IS NOT NULL AND ch.CloseDate = ch.MaxCloseDate THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM PostStatistics ps
    LEFT JOIN ClosedPostHistory ch ON ps.PostId = ch.PostId
),
FinalReport AS (
    SELECT 
        pwh.PostId,
        pwh.OwnerDisplayName,
        pwh.CommentCount,
        pwh.TotalBounty,
        pwh.CloseDate,
        pwh.CloseReasons,
        pwh.PostStatus,
        CASE 
            WHEN pwh.TotalBounty > 100 THEN 'High Bounty'
            WHEN pwh.TotalBounty BETWEEN 50 AND 100 THEN 'Medium Bounty'
            ELSE 'Low or No Bounty'
        END AS BountyLevel
    FROM PostWithHistory pwh
)
SELECT 
    fr.*,
    ur.ReputationLevel
FROM FinalReport fr
LEFT JOIN UserReputation ur ON fr.OwnerDisplayName = ur.Id::varchar(40)
WHERE fr.CommentCount > 5
ORDER BY fr.TotalBounty DESC, fr.PostId;
