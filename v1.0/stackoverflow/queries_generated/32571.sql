WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > '2023-01-01'
),
FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(DISTINCT co.Id) AS CommentCount,
        MAX(CASE WHEN ph.UserId IS NOT NULL THEN ph.UserDisplayName END) AS LastEditor
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments co ON p.Id = co.PostId
    LEFT JOIN 
        RecursivePostHistory ph ON p.Id = ph.PostId AND ph.rn = 1
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount, p.CreationDate, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT PostId) AS PostsCount
    FROM 
        Votes
    GROUP BY 
        UserId
    HAVING 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) > 50
)
SELECT 
    fp.Title,
    fp.Score,
    fp.ViewCount,
    fp.AnswerCount,
    fp.CommentCount,
    fp.LastEditor,
    u.DisplayName AS UserName,
    u.Reputation,
    u.CreationDate,
    CASE 
        WHEN t.PostsCount IS NOT NULL THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType
FROM 
    FilteredPosts fp
JOIN 
    Users u ON fp.OwnerDisplayName = u.DisplayName
LEFT JOIN 
    TopUsers t ON u.Id = t.UserId
WHERE 
    fp.ViewCount > (SELECT AVG(ViewCount) FROM Posts)
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
