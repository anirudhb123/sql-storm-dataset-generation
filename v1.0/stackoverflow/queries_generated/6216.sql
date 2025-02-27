WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ARRAY_AGG(c.Text) AS Comments,
        ARRAY_AGG(DISTINCT ph.PostHistoryTypeId) AS HistoryTypes,
        CASE 
            WHEN EXISTS (SELECT 1 FROM Posts pp WHERE pp.AcceptedAnswerId = p.Id) THEN 1
            ELSE 0
        END AS IsAcceptedAnswer
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.BadgeCount,
    us.UpVotes,
    us.DownVotes,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.Tags,
    pd.Comments,
    pd.HistoryTypes,
    pd.IsAcceptedAnswer
FROM 
    UserStats us
JOIN 
    PostDetails pd ON us.UserId = pd.PostId
ORDER BY 
    us.Reputation DESC, pd.Score DESC
LIMIT 100;
