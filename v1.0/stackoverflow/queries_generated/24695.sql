WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId IN (2, 3)) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.PostTypeId
),

ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        (SELECT Name FROM PostHistoryTypes pht WHERE pht.Id = ph.PostHistoryTypeId) AS HistoryTypeName
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Filtering for closed posts
),

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY SUM(v.VoteTypeId = 2) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(v.VoteTypeId) IS NOT NULL
    ORDER BY 
        UserRank
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CommentCount,
    rp.VoteCount,
    CASE 
        WHEN cp.Comment IS NULL THEN 'No Reason Provided'
        ELSE cp.Comment END AS CloseReason,
    u.DisplayName AS TopUser,
    u.UpVotes,
    u.DownVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPostHistory cp ON rp.PostId = cp.PostId
JOIN 
    TopUsers u ON u.UserRank = 1 -- Taking the top user based on rank
WHERE 
    rp.PostRank = 1 -- Only the top-ranked post for each PostType
  AND 
    rp.CreationDate > NOW() - INTERVAL '1 year' -- Posts created in the last year
ORDER BY 
    rp.VoteCount DESC, 
    rp.CommentCount DESC;
