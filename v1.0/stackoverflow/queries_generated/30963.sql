WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
        AND p.Score > 0
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Badges b
    WHERE 
        b.Date >= DATEADD(MONTH, -3, GETDATE())
    GROUP BY 
        b.UserId
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -2, GETDATE())
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.ANSWERCount,
        re.BadgeCount,
        pe.CommentCount,
        pe.UpvoteCount,
        pe.DownvoteCount,
        CASE 
            WHEN re.BadgeCount > 0 THEN 'Active User'
            ELSE 'New or Inactive User'
        END AS UserStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentBadges re ON re.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    LEFT JOIN 
        PostEngagement pe ON pe.PostId = rp.PostId
    WHERE 
        rp.Rank <= 10
)

SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.BadgeCount,
    tp.CommentCount,
    tp.UpvoteCount,
    tp.DownvoteCount,
    tp.UserStatus,
    (SELECT 
        STRING_AGG(DISTINCT TagName, ', ') 
     FROM 
        Tags t 
     WHERE 
        t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, LENGTH(p.Tags)-2), '>'))::int) 
                  FROM Posts p WHERE p.Id = tp.PostId)) AS TagsList
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
