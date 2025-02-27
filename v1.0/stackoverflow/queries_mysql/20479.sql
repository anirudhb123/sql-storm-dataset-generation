
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName
         FROM Posts p CROSS JOIN 
         (SELECT a.N FROM 
            (SELECT 1 AS N UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
             SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
             SELECT 9 UNION ALL SELECT 10) AS a) n
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1) AS tag ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag.TagName
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
        AND p.ViewCount > 0
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.AcceptedAnswerId, p.ViewCount
),
RankedPosts AS (
    SELECT 
        pd.*,
        @row_num := IF(@prev_AcceptedAnswerId = pd.AcceptedAnswerId, @row_num + 1, 1) AS Rank,
        @prev_AcceptedAnswerId := pd.AcceptedAnswerId
    FROM 
        PostDetails pd,
        (SELECT @row_num := 0, @prev_AcceptedAnswerId := NULL) AS vars
    ORDER BY 
        pd.AcceptedAnswerId, pd.Score DESC
),
PostsWithBadges AS (
    SELECT 
        rp.*,
        b.Name AS BadgeName,
        COUNT(b.Id) OVER (PARTITION BY rp.PostId) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
),
FinalOutput AS (
    SELECT 
        pwb.PostId,
        pwb.Title,
        pwb.Score,
        pwb.CommentCount,
        pwb.UpVoteCount,
        pwb.DownVoteCount,
        pwb.BadgeName,
        CASE 
            WHEN pwb.BadgeCount IS NULL THEN 'No Badge'
            ELSE 'Has Badge'
        END AS BadgeStatus
    FROM 
        PostsWithBadges pwb
    WHERE 
        pwb.Rank = 1
)

SELECT 
    *,
    (CASE 
        WHEN BadgeStatus = 'Has Badge' THEN 'Congratulations on your achievement!'
        ELSE 'Keep striving for that badge!'
    END) AS EncouragementMessage
FROM 
    FinalOutput
ORDER BY 
    CommentCount DESC, 
    Score DESC;
