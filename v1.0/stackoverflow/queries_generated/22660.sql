WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (1, 8) THEN 1 ELSE 0 END), 0) AS AcceptedAnswersAndBounties,
        DENSE_RANK() OVER (ORDER BY COUNT(V.Id) DESC) AS VoteRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.UserId AS OwnerId,
        COUNT(COALESCE(CM.Id, NULL)) AS CommentCount,
        COUNT(COALESCE(PH.Id, NULL)) AS HistoryCount,
        COALESCE(AVG(PH.CreationDate), P.CreationDate) AS AverageHistoryDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments CM ON P.Id = CM.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
    GROUP BY 
        P.Id
),
RankedPosts AS (
    SELECT 
        PD.*,
        RANK() OVER (ORDER BY PD.CommentCount DESC, PD.HistoryCount DESC) AS PostRank
    FROM 
        PostDetails PD
)
SELECT 
    R.UserId,
    R.DisplayName,
    ARRAY_AGG(DISTINCT 'Post Title: ' || RP.Title || ', Created On: ' || RP.CreationDate) AS PostDetails,
    R.TotalVotes,
    R.UpVotes,
    R.DownVotes,
    R.AcceptedAnswersAndBounties,
    RP.PostRank
FROM 
    UserVoteStats R
JOIN 
    RankedPosts RP ON RP.OwnerId = R.UserId
WHERE 
    R.VoteRank <= 5
    AND RP.PostRank <= 10
GROUP BY 
    R.UserId, R.DisplayName, RP.PostRank
ORDER BY 
    R.TotalVotes DESC, RP.PostRank ASC;

This SQL query covers various concepts such as Common Table Expressions (CTEs), LEFT JOINS, window functions, aggregate functions, correlated subqueries with conditional logic, and makes use of string concatenation for detailed output. It retrieves user statistics based on their voting activity and details of the top-ranked posts they have authored in the last year, showcasing the depth of available data in the schema.
