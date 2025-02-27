
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        @row_number := IF(@current_user = p.OwnerUserId, @row_number + 1, 1) AS Rank,
        @current_user := p.OwnerUserId,
        COALESCE(pc.CommentCount, 0) AS TotalComments,
        COALESCE(pa.AnswerCount, 0) AS TotalAnswers,
        COALESCE(up.UserReputation, 0) AS OwnerReputation
    FROM 
        Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(Id) AS CommentCount 
        FROM Comments 
        GROUP BY PostId
    ) pc ON p.Id = pc.PostId
    LEFT JOIN (
        SELECT ParentId, COUNT(Id) AS AnswerCount 
        FROM Posts 
        WHERE PostTypeId = 2 
        GROUP BY ParentId
    ) pa ON p.Id = pa.ParentId
    LEFT JOIN (
        SELECT Id AS UserId, Reputation AS UserReputation 
        FROM Users
    ) up ON p.OwnerUserId = up.UserId,
    (SELECT @row_number := 0, @current_user := '') AS init
    WHERE 
        p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
    ORDER BY p.OwnerUserId, p.ViewCount DESC
),
FilterPosts AS (
    SELECT 
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.TotalComments,
        rp.TotalAnswers,
        rp.OwnerReputation
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 AND (rp.TotalComments > 5 OR rp.TotalAnswers > 3)
)
SELECT 
    fp.Title,
    fp.ViewCount,
    fp.CreationDate,
    fp.TotalComments,
    fp.TotalAnswers,
    fp.OwnerReputation,
    CASE 
        WHEN fp.OwnerReputation IS NULL THEN 'No Reputation'
        WHEN fp.OwnerReputation < 100 THEN 'Newbie'
        ELSE 'Experienced'
    END AS UserStatus
FROM 
    FilterPosts fp
ORDER BY 
    fp.ViewCount DESC;
