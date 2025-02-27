WITH RankedUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    WHERE u.Reputation IS NOT NULL
), 
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    WHERE p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY p.Id, pt.Name
    HAVING COUNT(c.Id) > 5
), 
PostDetails AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.Score,
        pp.CreationDate,
        pp.PostType,
        pp.CommentCount,
        COALESCE(pht.Name, 'No History') AS PostHistory,
        GROUP_CONCAT(DISTINCT CONCAT('User: ', u.DisplayName, ' - Vote Type: ', vt.Name) ORDER BY u.DisplayName SEPARATOR '; ') AS Votes
    FROM TopPosts pp
    LEFT JOIN PostHistory ph ON pp.PostId = ph.PostId
    LEFT JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    LEFT JOIN Votes v ON pp.PostId = v.PostId
    LEFT JOIN Users u ON v.UserId = u.Id
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY pp.PostId
), 
FinalResults AS (
    SELECT 
        pu.UserRank,
        pd.Title,
        pd.Score,
        pd.CreationDate,
        pd.PostType,
        pd.CommentCount,
        pd.PostHistory,
        pd.Votes
    FROM RankedUsers pu
    JOIN PostDetails pd ON pu.Id = (SELECT OwnerUserId FROM Posts WHERE Id = pd.PostId)
)

SELECT 
    fr.UserRank,
    fr.Title,
    fr.Score,
    fr.CreationDate,
    fr.PostType,
    fr.CommentCount,
    FR.PostHistory,
    COALESCE(fr.Votes, 'No Votes') AS VoteDetails
FROM FinalResults fr
ORDER BY fr.UserRank, fr.Score DESC
LIMIT 100;
