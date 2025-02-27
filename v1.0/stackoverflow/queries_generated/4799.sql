WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.AcceptedAnswerId, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.*, 
        (UpVoteCount - DownVoteCount) AS NetVotes
    FROM 
        RankedPosts rp
    WHERE 
        PostRank = 1
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.CommentCount,
    fp.NetVotes,
    u.DisplayName,
    CASE 
        WHEN fp.AcceptedAnswerId = 0 THEN 'No Accepted Answer' 
        ELSE 'Has Accepted Answer' 
    END AS AnswerStatus,
    COALESCE(b.Name, 'No Badge') AS UserBadge
FROM 
    FilteredPosts fp
JOIN 
    Users u ON fp.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1
WHERE 
    fp.NetVotes > 0
ORDER BY 
    fp.NetVotes DESC, fp.CreationDate DESC
LIMIT 10;
