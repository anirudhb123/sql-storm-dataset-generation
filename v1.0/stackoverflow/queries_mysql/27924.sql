
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
         UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
),
MostVotedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title
    ORDER BY 
        VoteCount DESC
    LIMIT 5
),
TopCommentedPosts AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
    HAVING 
        COUNT(c.Id) > 10 
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        @row_num := IF(@prev_post_id = ph.PostId, @row_num + 1, 1) AS rn,
        @prev_post_id := ph.PostId
    FROM 
        PostHistory ph, (SELECT @row_num := 0, @prev_post_id := NULL) AS r
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    ORDER BY 
        ph.PostId, ph.CreationDate DESC
)

SELECT 
    p.Title,
    p.ViewCount,
    p.Score,
    tc.PostCount AS TagPostCount,
    mvp.VoteCount,
    tcp.CommentCount,
    rph.CreationDate AS RecentChangeDate,
    CASE 
        WHEN rph.PostHistoryTypeId = 10 THEN 'Closed'
        WHEN rph.PostHistoryTypeId = 11 THEN 'Reopened'
        ELSE 'No Recent Change'
    END AS RecentChangeType
FROM 
    Posts p
LEFT JOIN 
    TagCounts tc ON p.Tags LIKE CONCAT('%<', tc.TagName, '>%' )
LEFT JOIN 
    MostVotedPosts mvp ON p.Id = mvp.Id
LEFT JOIN 
    TopCommentedPosts tcp ON p.Id = tcp.PostId
LEFT JOIN 
    RecentPostHistory rph ON p.Id = rph.PostId AND rph.rn = 1
WHERE 
    p.CreationDate >= NOW() - INTERVAL 1 YEAR 
ORDER BY 
    p.Score DESC, 
    p.ViewCount DESC;
