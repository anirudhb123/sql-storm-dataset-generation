WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId,
        ParentId,
        Title,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Questions
    UNION ALL
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        rph.Level + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
UserReputationCTE AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
PostSummary AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT bh.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Badges bh ON bh.UserId = p.OwnerUserId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.ViewCount
),
FinalResults AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        up.ReputationRank,
        COALESCE(rph.Level, 0) AS AnswerLevel
    FROM 
        PostSummary ps
    LEFT JOIN 
        UserReputationCTE up ON up.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)
    LEFT JOIN 
        RecursivePostHierarchy rph ON rph.PostId = ps.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.ViewCount,
    fr.UpVotes,
    fr.DownVotes,
    fr.CommentCount,
    fr.ReputationRank,
    fr.AnswerLevel,
    CASE 
        WHEN fr.UpVotes > fr.DownVotes THEN 'Popular'
        WHEN fr.UpVotes < fr.DownVotes THEN 'Controversial'
        ELSE 'Neutral'
    END AS PostSentiment
FROM 
    FinalResults fr
ORDER BY 
    fr.ViewCount DESC, fr.UpVotes DESC;
