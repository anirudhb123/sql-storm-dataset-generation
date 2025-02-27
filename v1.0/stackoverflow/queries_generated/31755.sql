WITH RECURSIVE UserBadges AS (
    SELECT 
        b.UserId,
        b.Class as BadgeClass,
        COUNT(*) AS TotalBadges
    FROM 
        Badges b
    WHERE 
        b.Class IN (1, 2, 3) -- Only Gold, Silver, Bronze
    GROUP BY 
        b.UserId, b.Class
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentPost
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -6, CURRENT_TIMESTAMP)
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
ClosedQuestions AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        c.Name as CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON ph.Comment::int = c.Id
    WHERE 
        ph.PostHistoryTypeId = 10
),
FinalResults AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        ps.Title,
        ps.CommentCount,
        ps.UpVotes AS PostUpVotes,
        ps.DownVotes AS PostDownVotes,
        b.TotalBadges,
        cq.CloseReason
    FROM 
        TopUsers u
    JOIN 
        PostStatistics ps ON u.UserId = ps.OwnerUserId
    LEFT JOIN 
        UserBadges b ON u.UserId = b.UserId
    LEFT JOIN 
        ClosedQuestions cq ON ps.PostId = cq.PostId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    UpVotes,
    DownVotes,
    Title,
    CommentCount,
    PostUpVotes,
    PostDownVotes,
    TotalBadges,
    CloseReason
FROM 
    FinalResults
WHERE 
    TotalBadges > 0
ORDER BY 
    Reputation DESC,
    UpVotes DESC;

