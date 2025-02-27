
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.Title,
        p.Body,
        p.Score,
        p.ViewCount,
        p.Tags,
        COALESCE(Answers.AnswerCount, 0) AS AnswerCount,
        CASE 
            WHEN p.PostTypeId = 1 THEN (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2)
            ELSE NULL 
        END AS UpVotes,
        CASE 
            WHEN p.PostTypeId = 1 THEN (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3)
            ELSE NULL 
        END AS DownVotes
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            ParentId, 
            COUNT(*) AS AnswerCount 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) AS Answers ON p.Id = Answers.ParentId
    WHERE
        p.CreationDate >= (NOW() - INTERVAL 1 YEAR)
),
UsersRanked AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        @rank := @rank + 1 AS UserRank,
        u.Reputation,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount
    FROM 
        Users u, (SELECT @rank := 0) r
    WHERE 
        u.Reputation > 1000
    ORDER BY 
        u.Reputation DESC
),
PostedTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    INNER JOIN (
        SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
),
PopularTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        PostedTags 
    GROUP BY 
        Tag
    HAVING
        COUNT(*) > 10
),
PostHistoryData AS (
    SELECT 
        ph.PostId, 
        ph.UserId,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 12) THEN 1 ELSE 0 END) AS ClosedPostCount 
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.UserId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.Score,
    pd.ViewCount,
    pd.AcceptedAnswerId,
    pd.AnswerCount,
    ur.DisplayName AS TopUserDisplayName,
    ur.UserRank,
    ur.BadgeCount,
    pt.Tag AS PopularTag,
    ph.LastEditDate,
    ph.CloseReason,
    ph.ClosedPostCount
FROM 
    PostDetails pd
INNER JOIN 
    UsersRanked ur ON pd.OwnerUserId = ur.UserId
LEFT JOIN 
    PostHistoryData ph ON pd.PostId = ph.PostId
LEFT JOIN 
    PopularTags pt ON pt.Tag IN (SELECT Tag FROM PostedTags WHERE PostId = pd.PostId) 
WHERE 
    pd.ViewCount >= 100
ORDER BY 
    pd.Score DESC,
    ur.UserRank ASC,
    ph.LastEditDate DESC
LIMIT 50;
