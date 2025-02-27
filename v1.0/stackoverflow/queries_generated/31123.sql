WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- only questions
    GROUP BY 
        p.Id, u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS ChangeDate,
        ph.UserId,
        ph.Comment,
        p.Title,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ChangeRank
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Only interested in closed/reopened actions
),
RecentUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        SUM(COALESCE(b.Class, 0)) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- User created in the last year
    GROUP BY 
        u.Id
)
SELECT 
    p.PostId,
    p.Title,
    p.PostCreationDate,
    p.ViewCount,
    p.Score,
    p.Reputation,
    r.UpVotes,
    r.DownVotes,
    ph.ChangeType,
    ph.ChangeDate,
    u.UserId,
    u.DisplayName,
    ua.QuestionsAsked,
    ua.CommentsMade,
    ua.BadgeCount
FROM 
    RankedPosts r
JOIN 
    Posts p ON r.PostId = p.Id
LEFT JOIN (
    SELECT 
        ph.PostId,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
        END AS ChangeType,
        ph.ChangeDate
    FROM 
        PostHistoryDetails ph
    WHERE 
        ph.ChangeRank = 1
) ph ON r.PostId = ph.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    RecentUserActivity ua ON u.Id = ua.UserId
WHERE 
    r.PostRank = 1 -- Latest post per user
ORDER BY 
    p.Score DESC, 
    r.UpVotes DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
