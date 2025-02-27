WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(COUNT(c.Id) FILTER (WHERE c.Text IS NOT NULL), 0) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),
RecentActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
),
FilteredTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE 
        t.IsModeratorOnly = 0
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
FinalOutput AS (
    SELECT 
        rp.PostId,
        rp.Title,
        ra.UserId,
        ra.DisplayName,
        rt.TagName,
        rp.CommentCount,
        rp.UpVotes,
        rp.Rank,
        CASE 
            WHEN rp.Score IS NULL THEN 'No score' 
            ELSE CASE 
                WHEN rp.Score > 0 THEN 'Positive Score' 
                ELSE 'Negative Score' 
            END 
        END AS ScoreStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentActivity ra ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ra.UserId)
    LEFT JOIN 
        FilteredTags rt ON rt.PostCount > 5
    WHERE 
        rp.Rank <= 5 AND (rp.Score IS NOT NULL OR rp.CommentCount > 0)
)
SELECT 
    f.PostId,
    f.Title,
    f.DisplayName,
    f.TagName,
    f.CommentCount,
    f.UpVotes,
    f.ScoreStatus
FROM 
    FinalOutput f
ORDER BY 
    f.UpVotes DESC, f.CommentCount DESC;
This SQL query performs various complex operations, incorporating Common Table Expressions (CTEs), window functions, joins, and conditional logic to generate a list of top-ranked posts along with user activity and relevant tags. The use of COALESCE, FILTER, and advanced grouping adds to its complexity.
