
WITH UserVoteData AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5)  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.CreationDate,
        pa.CommentCount,
        pa.LastEditDate,
        @row_number := IF(@prev_id = pa.OwnerUserId, @row_number + 1, 1) AS CommentRank,
        @prev_id := pa.OwnerUserId
    FROM 
        PostActivity pa, (SELECT @row_number := 0, @prev_id := NULL) AS vars
    WHERE 
        pa.CommentCount > 0
    ORDER BY 
        pa.OwnerUserId, pa.CommentCount DESC
),
UserTopPosts AS (
    SELECT 
        ut.UserId,
        ut.DisplayName,
        tp.Title,
        tp.CommentCount,
        tp.LastEditDate,
        @top_post_rank := IF(@prev_user_id = ut.UserId, @top_post_rank + 1, 1) AS TopPostRank,
        @prev_user_id := ut.UserId
    FROM 
        UserVoteData ut, (SELECT @top_post_rank := 0, @prev_user_id := NULL) AS vars
    INNER JOIN 
        TopPosts tp ON ut.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
)
SELECT 
    ut.UserId,
    ut.DisplayName,
    ut.Title,
    ut.CommentCount,
    ut.LastEditDate,
    CASE 
        WHEN ut.TopPostRank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    COALESCE(ud.UpVotes, 0) AS UserUpVotes,
    COALESCE(ud.DownVotes, 0) AS UserDownVotes
FROM 
    UserTopPosts ut
LEFT JOIN 
    UserVoteData ud ON ut.UserId = ud.UserId
WHERE 
    ut.TopPostRank <= 3  
ORDER BY 
    ut.UserId, ut.CommentCount DESC, ut.LastEditDate DESC;
