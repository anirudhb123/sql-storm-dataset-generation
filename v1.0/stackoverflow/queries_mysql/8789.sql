
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        u.Reputation,
        p.OwnerUserId,
        @row_number := IF(@current_owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @current_owner_user_id := p.OwnerUserId
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @row_number := 0, @current_owner_user_id := NULL) AS vars
    WHERE
        p.PostTypeId = 1 AND
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 30 DAY)
    GROUP BY
        p.Id, p.Title, p.CreationDate, u.Reputation, p.OwnerUserId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    u.DisplayName,
    u.Reputation
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.UpVoteCount DESC, rp.CommentCount DESC;
