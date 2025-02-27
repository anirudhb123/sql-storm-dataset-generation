
WITH UserReputation AS (
    SELECT 
        Id as UserId, 
        Reputation,
        CASE 
            WHEN Reputation >= 100000 THEN 'Platinum'
            WHEN Reputation >= 50000 THEN 'Gold'
            WHEN Reputation >= 10000 THEN 'Silver'
            ELSE 'Bronze'
        END as BadgeType
    FROM Users
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        @row_number := IF(@prev_post_id = ph.PostId, @row_number + 1, 1) as EditRank,
        @prev_post_id := ph.PostId
    FROM PostHistory ph, (SELECT @row_number := 0, @prev_post_id := NULL) r
    WHERE ph.PostHistoryTypeId IN (4, 5, 6)
    ORDER BY ph.PostId, ph.CreationDate DESC
),
CombinedData AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.CreationDate as PostCreationDate,
        u.DisplayName as OwnerDisplayName,
        u.Reputation as OwnerReputation,
        ue.BadgeType,
        re.EditRank,
        COALESCE(c.Text, 'No comments') AS LatestComment,
        COALESCE(v.TotalVotes, 0) AS TotalVotes
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN UserReputation ue ON u.Id = ue.UserId
    LEFT JOIN RecentEdits re ON p.Id = re.PostId AND re.EditRank = 1
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(Id) AS TotalVotes 
        FROM Votes 
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId AND c.CreationDate = (
        SELECT MAX(cc.CreationDate) FROM Comments cc WHERE cc.PostId = p.Id
    )
    WHERE p.CreationDate < NOW() - INTERVAL 1 YEAR
)
SELECT 
    cd.PostId, 
    cd.Title, 
    cd.PostCreationDate, 
    cd.OwnerDisplayName, 
    cd.OwnerReputation,
    cd.BadgeType,
    COALESCE(cd.LatestComment, 'This post has no comments') as LatestPostComment,
    cd.EditRank,
    (SELECT COUNT(DISTINCT pl.RelatedPostId) 
     FROM PostLinks pl 
     WHERE pl.PostId = cd.PostId) as RelatedPostCount
FROM CombinedData cd
WHERE cd.OwnerReputation IS NOT NULL
ORDER BY cd.OwnerReputation DESC, cd.EditRank DESC
LIMIT 10 OFFSET 0;
